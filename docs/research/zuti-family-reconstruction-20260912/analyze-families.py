"""Read-only coherent-family audit. Only writes the explicitly selected report.

Compares bytecode after constant-pool and branch-target normalization; this is
structural semantic evidence, not proof of equivalent execution or JVM linkage.
No game class is removed, replaced, compiled or launched by this program.
"""
from pathlib import Path
import argparse
import hashlib
import json
import re
import runpy
import struct
from contextlib import ExitStack


def sha(data):
    return hashlib.sha256(data).hexdigest()


def parse(data):
    if data[:4] != b'\xca\xfe\xba\xbe':
        return None
    p = 8

    def take(n):
        nonlocal p
        value = data[p:p+n]
        if len(value) != n:
            raise ValueError('Truncated class')
        p += n
        return value

    def u2():
        return int.from_bytes(take(2), 'big')

    def u4():
        return int.from_bytes(take(4), 'big')

    cp = [None] * u2()
    i = 1
    while i < len(cp):
        tag = take(1)[0]
        if tag == 1:
            cp[i] = (tag, take(u2()).decode('utf-8', 'replace'))
        elif tag in (7, 8, 16, 19, 20):
            cp[i] = (tag, u2())
        elif tag in (9, 10, 11, 12, 17, 18):
            cp[i] = (tag, u2(), u2())
        elif tag in (3, 4):
            cp[i] = (tag, take(4).hex())
        elif tag in (5, 6):
            cp[i] = (tag, take(8).hex())
            i += 1
        elif tag == 15:
            cp[i] = (tag, take(1)[0], u2())
        else:
            raise ValueError('Unsupported constant tag ' + str(tag))
        i += 1

    def val(i):
        if not i:
            return None
        c = cp[i]
        if c[0] in (1, 3, 4, 5, 6):
            return c
        if c[0] in (7, 8, 16, 19, 20):
            return (c[0], val(c[1]))
        if c[0] == 15:
            return (c[0], c[1], val(c[2]))
        return (c[0], val(c[1]), val(c[2]))

    def utf(i):
        return cp[i][1]

    def cl(i):
        return utf(cp[i][1]) if i else None

    def attrs():
        return [(utf(u2()), take(u4())) for _ in range(u2())]

    fixed = {0x10: 1, 0x11: 2, 0x12: 1, 0x13: 2, 0x14: 2,
             **{o: 1 for o in range(0x15, 0x1a)},
             **{o: 1 for o in range(0x36, 0x3b)}, 0x84: 2,
             **{o: 2 for o in range(0x99, 0xa9)}, 0xa9: 1,
             **{o: 2 for o in range(0xb2, 0xb9)}, 0xb9: 4, 0xba: 4,
             0xbb: 2, 0xbc: 1, 0xbd: 2, 0xc0: 2, 0xc1: 2, 0xc5: 3,
             0xc6: 2, 0xc7: 2, 0xc8: 4, 0xc9: 4}
    cpops = {0x12, 0x13, 0x14, *range(0xb2, 0xbb), 0xbb, 0xbd, 0xc0, 0xc1, 0xc5}

    def codeattr(blob):
        size = int.from_bytes(blob[4:8], 'big')
        code = blob[8:8+size]
        pos = 0
        ins = []
        refs = []
        literals = []
        while pos < len(code):
            at = pos
            op = code[pos]
            pos += 1
            arg = None
            if op in (0xaa, 0xab):
                pos += (-pos) % 4
                default = at + int.from_bytes(code[pos:pos+4], 'big', signed=True)
                pos += 4
                if op == 0xaa:
                    low, high = struct.unpack_from('>ii', code, pos)
                    pos += 8
                    pairs = []
                    for key in range(low, high+1):
                        target = at + int.from_bytes(code[pos:pos+4], 'big', signed=True)
                        pos += 4
                        pairs.append((key, target))
                else:
                    count = int.from_bytes(code[pos:pos+4], 'big')
                    pos += 4
                    pairs = []
                    for _ in range(count):
                        key, offset = struct.unpack_from('>ii', code, pos)
                        pos += 8
                        pairs.append((key, at+offset))
                arg = ('switch', default, pairs)
            elif op == 0xc4:
                length = 5 if code[pos] == 0x84 else 3
                arg = code[pos:pos+length].hex()
                pos += length
            else:
                length = fixed.get(op, 0)
                raw = code[pos:pos+length]
                pos += length
                if op in cpops:
                    width = 1 if op == 0x12 else 2
                    index = int.from_bytes(raw[:width], 'big')
                    arg = (val(index), raw[width:].hex())
                    c = cp[index]
                    if c[0] in (9, 10, 11):
                        nt = cp[c[2]]
                        refs.append(('field' if c[0] == 9 else 'method', cl(c[1]), utf(nt[1]), utf(nt[2])))
                    if c[0] == 8:
                        literals.append(utf(c[1]))
                    if op == 0x13:
                        op = 0x12  # ldc_w versus ldc is a pool layout detail
                elif 0x99 <= op <= 0xa8 or op in (0xc6, 0xc7, 0xc8, 0xc9):
                    arg = ('branch', at+int.from_bytes(raw, 'big', signed=True))
                else:
                    arg = raw.hex()
            ins.append((at, op, arg))
        labels = {pc: i for i, (pc, _, _) in enumerate(ins)}
        labels[len(code)] = len(ins)
        normalized = []
        for _, op, arg in ins:
            if isinstance(arg, tuple) and arg[0] == 'branch':
                arg = ('branch', labels[arg[1]])
            elif isinstance(arg, tuple) and arg[0] == 'switch':
                arg = ('switch', labels[arg[1]], [(k, labels[t]) for k, t in arg[2]])
            normalized.append((op, arg))
        exat = 8+size
        excount = int.from_bytes(blob[exat:exat+2], 'big')
        exceptions = []
        for j in range(excount):
            a, b, handler, typ = struct.unpack_from('>HHHH', blob, exat+2+j*8)
            exceptions.append((labels[a], labels[b], labels[handler], cl(typ)))
        canonical = [normalized, exceptions]
        return {'normalized_sha256': sha(json.dumps(canonical, sort_keys=True).encode()),
                'instructions': len(ins), 'refs': refs, 'literals': literals,
                'normalized': normalized}

    access = u2()
    name = cl(u2())
    superclass = cl(u2())
    interfaces = [cl(u2()) for _ in range(u2())]
    groups = []
    for kind in ('field', 'method'):
        group = []
        for _ in range(u2()):
            member = {'access': u2(), 'name': utf(u2()), 'descriptor': utf(u2())}
            attributes = attrs()
            member['attributes'] = [n for n, _ in attributes]
            for n, blob in attributes:
                if n == 'Code':
                    member.update(codeattr(blob))
                elif n == 'ConstantValue':
                    member['constant'] = val(int.from_bytes(blob, 'big'))
            group.append(member)
        groups.append(group)
    # Historical loose classes can carry malformed terminal class attributes.
    # Keep code/member evidence, record this separately; never silently certify
    # JVM format validity. The older inventory never inspected this area.
    terminal_error = None
    try:
        attributes = attrs()
        if p != len(data):
            terminal_error = 'Trailing bytes: ' + str(len(data)-p)
    except (ValueError, IndexError, TypeError) as error:
        terminal_error = str(error)
    refs = []
    for c in cp:
        if c and c[0] in (9, 10, 11):
            nt = cp[c[2]]
            refs.append(('field' if c[0] == 9 else 'method', cl(c[1]), utf(nt[1]), utf(nt[2])))
    return {'name': name, 'super': superclass, 'interfaces': interfaces,
            'access': access, 'major': int.from_bytes(data[6:8], 'big'),
            'fields': groups[0], 'methods': groups[1], 'refs': refs,
            'class_refs': sorted({cl(i) for i, c in enumerate(cp) if c and c[0] == 7}),
            'utf': [c[1] for c in cp if c and c[0] == 1],
            'sha256': sha(data), 'bytes': len(data), 'terminal_attributes_error': terminal_error}


def member_delta(current, donor):
    result = {}
    for kind in ('fields', 'methods'):
        before = {(m['name'], m['descriptor']): m for m in current[kind]}
        after = {(m['name'], m['descriptor']): m for m in donor[kind]}
        modified = []
        for k in sorted(before.keys() & after.keys()):
            a, b = before[k], after[k]
            if (a.get('normalized_sha256'), a.get('constant'), a['access']) != (b.get('normalized_sha256'), b.get('constant'), b['access']):
                modified.append({'name': k[0], 'descriptor': k[1],
                    'current_access': a['access'], 'donor_access': b['access'],
                    'current_body': a.get('normalized_sha256'), 'donor_body': b.get('normalized_sha256'),
                    'current_mentions_zuti': any('zuti' in str(x).lower() for x in a.get('refs', []) + a.get('literals', [])),
                    'current_refs': a.get('refs', []) if k[0].startswith('access$') else None,
                    'donor_refs': b.get('refs', []) if k[0].startswith('access$') else None})
        result[kind] = {'only_current': sorted(before.keys()-after.keys()),
                        'only_donor': sorted(after.keys()-before.keys()), 'modified': modified}
    return result


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--repository-root', type=Path, required=True)
    ap.add_argument('--output', type=Path, required=True)
    ap.add_argument('--overlay', action='append', default=[], metavar='CLASS=PATH',
                    help='Read a rebuilt delegated class as the simulated future override')
    args = ap.parse_args()
    root = args.repository_root.resolve()
    old = json.loads((root/'docs/research/zuti-removal-20260912/inventory.json').read_text(encoding='utf-8'))
    # This is a preflight transition audit. After application reproduce against
    # the archived pre-removal snapshot, not an already modified active tree.
    for item in old['candidates']:
        source = root/item['path']
        if not source.is_file() or sha(source.read_bytes()) != item['sha256']:
            raise ValueError('Baseline candidate changed or absent: ' + str(source))
    sfs = runpy.run_path(str(root/'tools/Analyze-Sfs.py'), run_name='family_sfs')
    loose = {}
    all_loose = []
    duplicates = []
    for path in sorted([p for p in (root/'Files').iterdir() if p.is_file() and re.fullmatch('[0-9A-Fa-f]{16}', p.name)] + list((root/'Files').rglob('*.class'))):
        try:
            c = parse(path.read_bytes())
        except Exception as error:
            raise ValueError(str(path)) from error
        if not c:
            continue
        c['path'] = str(path.relative_to(root))
        all_loose.append(c)
        if c['name'] in loose:
            duplicates.append([c['name'], loose[c['name']]['path'], c['path']])
        loose[c['name']] = c
    direct = {c['class'] for c in old['candidates']}
    roots = {n.split('$')[0] for n in direct}
    excluded_roots = {'com/maddox/il2/'+n for n in ('engine/Config', 'fm/Controls', 'fm/Motor', 'fm/RealFlightModel', 'fm/FlightModelMain', 'objects/effects/Explosions')}
    changed = {n for n in loose if n.split('$')[0] in roots-excluded_roots}
    overlays = {}
    for argument in args.overlay:
        name, path = argument.split('=', 1)
        name = name.replace('.', '/')
        if name not in excluded_roots:
            raise ValueError('Overlay outside delegated scope: ' + name)
        c = parse(Path(path).read_bytes())
        if c['name'] != name or c['major'] > 47 or any('zuti' in t.lower() for t in c['utf']):
            raise ValueError('Invalid clean Java 47 overlay: ' + name)
        c['path'] = str(Path(path).resolve())
        overlays[name] = c
    profiles = {'4.08m': '4.08 Mods ON (NO 6DOF)', '4.09b': '4.09 Mods ON (NO 6DOF)', '4.09m': '4.09 final Mods ON (NO 6DOF)'}
    report = {'scope': 'Proposed family fallback only; Config, Controls, Explosions and three FM classes delegated; no runtime mutation.',
              'direct_input_count': len(direct), 'loose_count': len(loose), 'duplicates': duplicates,
              'excluded_roots': sorted(excluded_roots), 'family_fallback_count': len(changed),
              'families': [], 'profiles': {}, 'named_zuti_classes': sorted(n for n in changed if 'zuti' in n.lower()),
              'fallback_classes': [{'class': n, 'path': loose[n]['path'], 'sha256': loose[n]['sha256']} for n in sorted(changed)]}
    report['fallback_files'] = [{'class': c['name'], 'path': c['path'], 'sha256': c['sha256'], 'bytes': c['bytes']}
                                for c in all_loose if c['name'] in changed]
    report['rebuilt_overlays'] = [{'class': n, 'path': c['path'], 'sha256': c['sha256'],
                                  'bytes': c['bytes'], 'java_major': c['major']} for n, c in overlays.items()]
    report['terminal_attributes_anomalies'] = [{'class': c['name'], 'path': c['path'],
        'proposed_family_fallback': c['name'] in changed, 'error': c['terminal_attributes_error']}
        for c in all_loose if c['terminal_attributes_error']]
    for family in sorted(roots):
        report['families'].append({'family': family, 'delegated': family in excluded_roots,
            'direct': sorted(n for n in direct if n.split('$')[0] == family),
            'companions': sorted(n for n in loose if n not in direct and n.split('$')[0] == family)})
    for version, directory in profiles.items():
        archive_path = root/'_Game Switcher'/directory/'files.SFS'
        original_path = root/'_Game Switcher'/directory.replace('Mods ON (NO 6DOF)', 'Mods OFF (Original)')/'files.SFS'
        expected = {
            '4.08m': ('e00f86b80183313b846f72f153a9102a1dc40afbb90323de8ac7de34ded0d5fd', '42342ce1089c42b4fbb61f6cfc3850f3ac27fafe6f4192cd7c6cf042e056f7ec'),
            '4.09b': ('53b97e4993c17decdeec6e4e46e70f42ed01a625ae9aeb274a14327c399f890e', '08682f88511336d083a068a2d3de81bc02f2ae8a27df61666fc91f3dff95bcc2'),
            '4.09m': ('5cb81d4fae005429b701ce3dcac001892db2c66d0aecee0a00e918d5e8892e71', 'fcfce245ec23ff314c6cd86e9a51d563d091cff74ddd0b46b704b670c0340c6a')}
        if (sha(archive_path.read_bytes()), sha(original_path.read_bytes())) != expected[version]:
            raise ValueError('Donor archive changed: ' + version)
        print('PROFILE ' + version, flush=True)
        with ExitStack() as stack:
            archive = stack.enter_context(sfs['SfsArchive'](archive_path))
            original = stack.enter_context(sfs['SfsArchive'](original_path))
            cache = {}
            def stock(n):
                if n not in cache:
                    try:
                        data = archive.extract_class(n.replace('/', '.'))
                        c = parse(data)
                        try:
                            c['same_as_original'] = data == original.extract_class(n.replace('/', '.'))
                        except KeyError:
                            c['same_as_original'] = False
                        cache[n] = c
                    except KeyError:
                        cache[n] = None
                return cache[n]
            def effective(n, altered):
                if altered and n in overlays:
                    return overlays[n]
                return stock(n) if n in altered else loose.get(n) or stock(n)
            def resolve(owner, kind, name, desc, altered, seen=None):
                seen = set() if seen is None else seen
                if owner in seen:
                    return False
                seen.add(owner)
                c = effective(owner, altered)
                if not c:
                    return False
                if any(m['name'] == name and m['descriptor'] == desc for m in c[kind+'s']):
                    return True
                if name == '<init>':
                    return False
                return any(resolve(n, kind, name, desc, altered, seen) for n in [c['super']]+c['interfaces'] if n)
            def resolved_member(owner, kind, name, desc, altered, seen=None):
                seen = set() if seen is None else seen
                if owner in seen:
                    return None
                seen.add(owner)
                c = effective(owner, altered)
                if not c:
                    return None
                for m in c[kind+'s']:
                    if m['name'] == name and m['descriptor'] == desc:
                        return (owner, m)
                if name == '<init>':
                    return None
                for parent in [c['super']]+c['interfaces']:
                    if parent:
                        found = resolved_member(parent, kind, name, desc, altered, seen)
                        if found:
                            return found
                return None
            def subclass(child, parent, altered, seen=None):
                if child == parent:
                    return True
                seen = set() if seen is None else seen
                if child in seen:
                    return False
                seen.add(child)
                c = effective(child, altered)
                return bool(c and any(subclass(x, parent, altered, seen) for x in [c['super']]+c['interfaces'] if x))
            def accessible(caller, target, altered):
                owner, member = target
                flags = member['access']
                if flags & 1:
                    return True
                if flags & 2:
                    return caller == owner
                if caller.rsplit('/', 1)[0] == owner.rsplit('/', 1)[0]:
                    return True
                return bool(flags & 4 and subclass(caller, owner, altered))
            # Analyze existing loose callers AND all donor classes transitively
            # reached through constant-pool class references. External/JRE and
            # classes residing in other SFS cannot be resolved by files.SFS alone.
            changes = []
            for n in sorted({n for n in loose if n.split('$')[0] in roots}):
                a, b = loose[n], stock(n)
                delta = member_delta(a, b) if b else None
                changes.append({'class': n, 'path': a['path'], 'delegated': n.split('$')[0] in excluded_roots,
                    'direct': n in direct, 'current_sha256': a['sha256'], 'donor_exists': bool(b),
                    'donor_sha256': b['sha256'] if b else None,
                    'same_as_original': b.get('same_as_original') if b else None,
                    'donor_has_zuti': any('zuti' in t.lower() for t in b['utf']) if b else None,
                    'same_as_donor': bool(b and a['sha256'] == b['sha256']),
                    'delta': delta})
            # Restrict new linkage failures to changes, comparing before/after.
            # Recursively visit stock callees/classes so newly exposed SFS code
            # cannot silently call incompatible surviving loose subclasses.
            effective_nodes = dict((n, effective(n, changed)) for n in loose)
            queue = [c for c in effective_nodes.values() if c]
            scanned = set(effective_nodes)
            external_unresolved = set()
            while queue:
                c = queue.pop()
                for ref in c['class_refs'] + [c['super']] + c['interfaces']:
                    if not ref or ref in scanned or ref.startswith('['):
                        continue
                    scanned.add(ref)
                    x = effective(ref, changed)
                    if x:
                        effective_nodes[ref] = x
                        queue.append(x)
                    elif ref.startswith('com/maddox/'):
                        external_unresolved.add(ref)
            failures = []
            access_failures = []
            static_changes = []
            missing_classes = []
            for n, c in sorted(effective_nodes.items()):
                if not c:
                    continue
                before_c = effective(n, set())
                before_refs = set(map(tuple, before_c['refs'])) if before_c else set()
                for kind, owner, member, desc in c['refs']:
                    target_before = resolved_member(owner, kind, member, desc, set())
                    target_after = resolved_member(owner, kind, member, desc, changed)
                    if target_before and target_after:
                        if accessible(n, target_before, set()) and not accessible(n, target_after, changed):
                            access_failures.append({'caller': n, 'owner': owner, 'kind': kind, 'member': member,
                                'descriptor': desc, 'current_access': target_before[1]['access'], 'donor_access': target_after[1]['access']})
                        if (target_before[1]['access'] ^ target_after[1]['access']) & 8:
                            static_changes.append({'caller': n, 'owner': owner, 'kind': kind, 'member': member, 'descriptor': desc})
                    # Baseline calls already failing are listed separately only
                    # when introduced by this donor; do not claim they are new.
                    if not resolve(owner, kind, member, desc, changed):
                        before_ok = resolve(owner, kind, member, desc, set())
                        introduced = (kind, owner, member, desc) not in before_refs
                        if before_ok or (introduced and owner in loose):
                            failures.append({'caller': n, 'caller_origin': 'donor' if n in changed or n not in loose else 'loose',
                                'kind': kind, 'owner': owner, 'member': member, 'descriptor': desc,
                                'resolved_before': before_ok, 'introduced_reference': introduced})
                for ref in c['class_refs']:
                    if ref in changed and effective(ref, changed) is None:
                        missing_classes.append({'caller': n, 'class': ref})
            access_mismatch = []
            for item in changes:
                if item['delta']:
                    for m in item['delta']['methods']['modified']:
                        if m['name'].startswith('access$') and m['current_body'] != m['donor_body']:
                            access_mismatch.append({'class': item['class'], **m})
            report['profiles'][version] = {
                'archive': str(archive_path), 'archive_sha256': sha(archive_path.read_bytes()),
                'original_archive': str(original_path), 'original_sha256': sha(original_path.read_bytes()),
                'changes': changes, 'access_same_signature_different_body': access_mismatch,
                'effective_class_nodes': len(effective_nodes),
                'new_linkage_failures': failures, 'missing_changed_classes': missing_classes,
                'new_member_access_failures': access_failures, 'changed_static_instance_members': static_changes,
                'effective_zuti_class_strings': [{'class': n, 'strings': [t for t in c['utf'] if 'zuti' in t.lower()]}
                    for n, c in effective_nodes.items() if c and any('zuti' in t.lower() for t in c['utf'])],
                'stock_bornplace_reader': {'class_sha256': stock('com/maddox/il2/game/Mission')['sha256'],
                    'method': next(m for m in stock('com/maddox/il2/game/Mission')['methods'] if m['name'] == 'loadBornPlaces')},
                'unresolved_maddox_class_names_in_files_sfs_only': sorted(external_unresolved),
                'donor_cache_count': len(cache)}
            print(json.dumps({'version': version, 'family_members': len(changes),
                'same': sum(x['same_as_donor'] for x in changes),
                'donors': sum(x['donor_exists'] for x in changes),
                'access_body_mismatches': len(access_mismatch),
                'new_linkage_failures': len(failures), 'missing_changed_classes': len(missing_classes),
                'new_access_failures': len(access_failures), 'static_changes': len(static_changes),
                'effective_nodes': len(effective_nodes)}), flush=True)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print('REPORT=' + str(args.output), flush=True)


if __name__ == '__main__':
    main()
