"""Read-only inventory. Writes only the explicitly named audit JSON beside itself."""
from pathlib import Path
import argparse, hashlib, json, re, runpy, struct

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--repository-root', required=True, type=Path)
parser.add_argument('--output', required=True, type=Path)
args = parser.parse_args()
ROOT = args.repository_root.resolve()
OUT = args.output.resolve()
SFS = runpy.run_path(str(ROOT/'tools/Analyze-Sfs.py'), run_name='audit_sfs')

def parse(data):
    if data[:4] != b'\xca\xfe\xba\xbe': return None
    pos=8
    def u2():
        nonlocal pos
        v=int.from_bytes(data[pos:pos+2],'big');pos+=2;return v
    def skip_attrs():
        nonlocal pos
        for _ in range(u2()):
            u2();n=int.from_bytes(data[pos:pos+4],'big');pos+=4+n
    count=u2();cp=[None]*count;i=1
    while i<count:
        tag=data[pos];pos+=1
        if tag==1:
            n=u2();cp[i]=(tag,data[pos:pos+n].decode('utf-8','replace'));pos+=n
        elif tag in (7,8,16,19,20):cp[i]=(tag,u2())
        elif tag in (9,10,11,12,17,18):cp[i]=(tag,u2(),u2())
        elif tag in (3,4):pos+=4
        elif tag in (5,6):pos+=8;i+=1
        elif tag==15:pos+=3
        else:raise ValueError('Unknown CP tag '+str(tag))
        i+=1
    def utf(i):return cp[i][1]
    def cl(i):return utf(cp[i][1]) if i else None
    flags=u2();name=cl(u2());sup=cl(u2());interfaces=[cl(u2()) for _ in range(u2())]
    sets=[]
    for typ in ('field','method'):
        members=[]
        for _ in range(u2()):
            access=u2();n=utf(u2());desc=utf(u2());skip_attrs();members.append((n,desc,access))
        sets.append(members)
    refs=[]
    for value in cp:
        if value and value[0] in (9,10,11):
            nt=cp[value[2]]
            refs.append((('field' if value[0]==9 else 'method'),cl(value[1]),utf(nt[1]),utf(nt[2])))
    return dict(name=name,super=sup,interfaces=interfaces,fields=sets[0],methods=sets[1],refs=refs,
                utf=[v[1] for v in cp if v and v[0]==1],major=int.from_bytes(data[6:8],'big'))

loose={}; duplicates=[];errors=[];scanned=0
paths=[p for p in (ROOT/'Files').iterdir() if p.is_file() and re.fullmatch('[0-9A-Fa-f]{16}',p.name)]
paths += list((ROOT/'Files').rglob('*.class'))
for path in paths:
    data=path.read_bytes()
    try:c=parse(data)
    except Exception as e:errors.append({'path':str(path.relative_to(ROOT)),'error':repr(e)});continue
    if not c:continue
    scanned+=1;c['path']=str(path.relative_to(ROOT));c['sha256']=hashlib.sha256(data).hexdigest();c['bytes']=len(data)
    if c['name'] in loose:duplicates.append({'class':c['name'],'first':loose[c['name']]['path'],'second':c['path']})
    loose[c['name']]=c

archive_path=ROOT/'_Game Switcher/4.09m Mods ON (NO 6DOF)/files.SFS'
original_path=ROOT/'_Game Switcher/4.09m Mods OFF (Original)/files.SFS'
expected_archives={archive_path:'5cb81d4fae005429b701ce3dcac001892db2c66d0aecee0a00e918d5e8892e71',
    original_path:'fcfce245ec23ff314c6cd86e9a51d563d091cff74ddd0b46b704b670c0340c6a'}
for path, expected in expected_archives.items():
    actual=hashlib.sha256(path.read_bytes()).hexdigest()
    if actual!=expected:raise ValueError('Unrecognised 4.09m baseline: '+str(path)+' '+actual)
stock_cache={}
direct={n:c for n,c in loose.items() if any('zuti' in t.lower() for t in c['utf'])}
with SFS['SfsArchive'](archive_path) as archive, SFS['SfsArchive'](original_path) as original:
    def stock(name):
        if name not in stock_cache:
            try:
                data=archive.extract_class(name.replace('/','.'));c=parse(data)
                c['sha256']=hashlib.sha256(data).hexdigest();c['bytes']=len(data)
                try:c['same_as_original']=data==original.extract_class(name.replace('/','.'))
                except KeyError:c['same_as_original']=False
                stock_cache[name]=c
            except KeyError:stock_cache[name]=None
        return stock_cache[name]
    def effective(name, changed):return stock(name) if name in changed else loose.get(name) or stock(name)
    def resolve(owner,typ,name,desc,changed,seen=None):
        seen=set() if seen is None else seen
        if owner in seen:return False
        seen.add(owner);c=effective(owner,changed)
        if not c:return False
        if any(x[0]==name and x[1]==desc for x in c[typ+'s']):return True
        if name=='<init>':return False
        return any(resolve(n,typ,name,desc,changed,seen) for n in [c['super']]+c['interfaces'] if n)
    def ancestry_changed(owner,changed,seen=None):
        seen=set() if seen is None else seen
        if owner in changed:return True
        if owner in seen:return False
        seen.add(owner);c=loose.get(owner) or stock(owner)
        return bool(c and any(ancestry_changed(n,changed,seen) for n in [c['super']]+c['interfaces'] if n))
    candidates=[]
    for n,c in sorted(direct.items()):
        s=stock(n)
        candidates.append({'class':n,'path':c['path'],'bytes':c['bytes'],'sha256':c['sha256'],
            'named_zuti':'zuti' in n.lower(),'zuti_strings':[x for x in c['utf'] if 'zuti' in x.lower()],
            'stock_exists':s is not None,'stock_same_in_on_off':s['same_as_original'] if s else None,
            'stock_has_zuti':any('zuti' in x.lower() for x in s['utf']) if s else None,
            'stock_sha256':s['sha256'] if s else None,
            'members_absent_in_stock':{'fields':[x for x in c['fields'] if not s or (x[0],x[1]) not in {(a,b) for a,b,_ in s['fields']}],
                'methods':[x for x in c['methods'] if not s or (x[0],x[1]) not in {(a,b) for a,b,_ in s['methods']}]}})
    breakages=[]
    for n,c in loose.items():
        if n in direct:continue
        for typ,owner,member,desc in c['refs']:
            if ancestry_changed(owner,direct) and resolve(owner,typ,member,desc,set()) and not resolve(owner,typ,member,desc,direct):
                breakages.append({'caller':n,'caller_path':c['path'],'kind':typ,'owner':owner,'member':member,'descriptor':desc})
    retained_companions=[]
    roots={n.split('$')[0] for n in direct if '$' in n or any(k.startswith(n+'$') for k in loose)}
    for n,c in loose.items():
        if n not in direct and n.split('$')[0] in roots:
            s=stock(n);retained_companions.append({'class':n,'path':c['path'],'stock_exists':s is not None,'same_as_stock':bool(s and s['sha256']==c['sha256'])})
    donors=[]
    for path in (ROOT/'test-assets/aoc-v1.15/donor-hsfx4').iterdir():
        data=path.read_bytes();c=parse(data)
        donors.append({'class':c['name'],'path':str(path.relative_to(ROOT)),'sha256':hashlib.sha256(data).hexdigest(),
            'zuti_strings':[t for t in c['utf'] if 'zuti' in t.lower()],
            'aoc_strings':[t for t in c['utf'] if any(s in t.lower() for s in ('aoc','coef','tempoilmin','magneto'))]})
    hybrid_names={'com/maddox/il2/fm/Controls','com/maddox/il2/fm/Motor','com/maddox/il2/objects/effects/Explosions'}
    provisional=set(direct)-hybrid_names
    rounds=[]
    for iteration in range(10):
        missing=[]
        for n,c in loose.items():
            if n in provisional:continue
            for typ,owner,member,desc in c['refs']:
                if ancestry_changed(owner,provisional) and resolve(owner,typ,member,desc,set()) and not resolve(owner,typ,member,desc,provisional):
                    missing.append({'caller':n,'caller_path':c['path'],'kind':typ,'owner':owner,'member':member,'descriptor':desc})
        additions={b['caller'] for b in missing if '$' in b['caller'] and b['caller'].split('$')[0] in {n.split('$')[0] for n in provisional}}
        rounds.append({'iteration':iteration,'changed_count':len(provisional),'broken_refs':len(missing),'added_family_callers':sorted(additions)})
        if not additions:break
        provisional.update(additions)
    provisional_report={'scope':'Simulation only: three hybrid classes remain unchanged provisionally and MUST be rebuilt without Zuti; this is not a safe deletion list.',
        'hybrids_requiring_rebuild':sorted(hybrid_names),'rounds':rounds,'final_candidate_count':len(provisional),
        'remaining_linkage_breakages':missing,
        'classes':[{'class':n,'path':loose[n]['path'],'stock_exists':stock(n) is not None} for n in sorted(provisional)]}
    report={'scope':'Static read-only; candidate set is dependency evidence, not an approved deletion list. No runtime proof.',
        'archive':str(archive_path),'archive_sha256':hashlib.sha256(archive_path.read_bytes()).hexdigest(),
        'original_archive':str(original_path),'original_archive_sha256':hashlib.sha256(original_path.read_bytes()).hexdigest(),
        'scanned_loose_files':scanned,'unique_classes':len(loose),'parse_errors':errors,'duplicates':duplicates,
        'direct_candidate_count':len(candidates),'named_zuti_count':sum(c['named_zuti'] for c in candidates),
        'stock_replacement_count':sum(c['stock_exists'] for c in candidates),
        'candidates':candidates,'residual_linkage_breakages':breakages,'unmarked_family_companions':retained_companions,'aoc_donors':donors,
        'provisional_family_closure':provisional_report}
OUT.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k not in ('candidates','unmarked_family_companions','aoc_donors','residual_linkage_breakages','provisional_family_closure')},ensure_ascii=False,indent=2))
print('PROVISIONAL_CLOSURE='+json.dumps({k:v for k,v in provisional_report.items() if k!='classes'},ensure_ascii=False))
print('REPORT='+str(OUT))
