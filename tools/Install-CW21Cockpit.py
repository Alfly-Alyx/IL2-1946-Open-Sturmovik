#!/usr/bin/env python3
"""Audit the authentic 4.09 cockpit against the current API before installation.

No game is launched. Only --apply installs the four cockpit classes, their
resources and our stock-preserving CW_21 patch. The donor aircraft/parent are
deliberately excluded. The complete donor ZIP must be retained separately.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parent.parent
LIB = runpy.run_path(str(ROOT / 'tools/Audit-JavaClasses.py'))
IDENTITY = runpy.run_path(str(ROOT / 'tools/Audit-AirIniAircraft.py'))['parse_class']
SFS = runpy.run_path(str(ROOT / 'tools/Analyze-Sfs.py'))
HELPER = 'com.maddox.il2.objects.air.OpenSturmovikCW21LoadoutList'
parse = LIB['parse_class']
ApiClass = LIB['ApiClass']
COCKPITS = {
    '21CA8D7CE1D2BD0C': 'E9105507EC36265DFADF4DA10274872E1E07C6AB79B3615A93BE8BFF3216F844',
    '68E6863AAE2BAB5C': 'B28D34D624F259FE74D3F0DCE7828DD9ED8458C3E178A46C5BE176AEEE52F633',
    'BAB3AB548B9EE8A4': 'BC86ECF8ACB4995641DEE8C694101978E415ED98877D923CC3EF894FCB0752F6',
    'BC0B01A0EB339004': '7C529CAD656340BFE43450BA738AD8B94DB6A53CC7D2337169B7A6D451C8D172',
}
def sha(data):
    return hashlib.sha256(data).hexdigest().upper()

def class_address(dotted_name):
    value = SFS['finger_int'](ord(c) for c in f'sdw{dotted_name}cwc2w9e')
    return f"{SFS['finger_string'](0, f'cod/{value}') & 0xFFFFFFFFFFFFFFFF:016X}"

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--donor-root', type=Path, required=True)
    p.add_argument('--dump-root', type=Path, required=True)
    p.add_argument('--rt-jar', type=Path, required=True)
    p.add_argument('--files-sfs', type=Path,
                   default=ROOT / '_Game Switcher/4.09 final Mods ON (NO 6DOF)/files.SFS',
                   help='Exact 4.09m profile archive used when an effective loose class is absent.')
    p.add_argument('--source-archive', type=Path, default=Path('D:/Projets/GITHUB/#res/IL2 1946/Mods/Utilisés/Cockpit_CW-21_for409.zip'))
    p.add_argument('--apply', action='store_true')
    p.add_argument('--replace-previous-cw21', action='store_true',
                   help='Allow replacing only a hash-verified previous CW-21 patch, with backup.')
    args = p.parse_args()
    args.files_sfs = args.files_sfs.resolve()
    sfs_origin = (args.files_sfs.relative_to(ROOT).as_posix() if args.files_sfs.is_relative_to(ROOT)
                  else str(args.files_sfs))
    assert subprocess.check_output(['git', '-C', str(ROOT), 'branch', '--show-current'], text=True).strip() == 'v1.15'
    assert Path(subprocess.check_output(['git', '-C', str(ROOT), 'rev-parse', '--show-toplevel'], text=True).strip()).resolve() == ROOT
    donor = args.donor_root.resolve()
    stock = args.dump_root / 'com/maddox/il2/objects/air/CW_21.class'
    stock_class = parse(stock.read_bytes())
    assert sha(stock.read_bytes()) == 'AB31568D9645B8F665B24262162920B3B01FD8057A024DF9A0230513D9210C65'
    assert stock_class.name == 'com/maddox/il2/objects/air/CW_21' and stock_class.major == 47
    assert b'cockpitClass' not in stock.read_bytes()
    build = ROOT / 'build/aircraft-patcher'
    build.mkdir(parents=True, exist_ok=True)
    assert sha(args.files_sfs.read_bytes()) == '5CB81D4FAE005429B701CE3DCAC001892DB2C66D0AECEE0A00E918D5E8892E71', \
        'Unrecognised 4.09m modded files.SFS'
    sfs_cache = {}
    def sfs_class(name):
        if name not in sfs_cache:
            with SFS['SfsArchive'](args.files_sfs) as archive:
                try:
                    sfs_cache[name] = archive.extract_class(name.replace('/', '.'))
                except KeyError:
                    sfs_cache[name] = None
        return sfs_cache[name]
    effective_source = ROOT / 'Files/4B598398AD1D180C'
    if effective_source.is_file():
        effective_bytes = effective_source.read_bytes()
        effective_origin = 'Files/4B598398AD1D180C'
    else:
        effective_bytes = sfs_class('com/maddox/il2/objects/air/Aircraft')
        assert effective_bytes is not None, 'Effective Aircraft missing from loose files and exact profile SFS'
        effective_source = build / 'EffectiveAircraft-from-SFS.class'
        effective_source.write_bytes(effective_bytes)
        effective_origin = sfs_origin + ':com/maddox/il2/objects/air/Aircraft'
    exports = sum((['--add-exports', 'java.base/jdk.internal.org.objectweb.asm' + suffix + '=ALL-UNNAMED']
                   for suffix in ('', '.tree', '.tree.analysis')), [])
    subprocess.run(['javac', *exports, '-d', str(build),
                    str(ROOT / 'tools/java/OpenSturmovikAircraftPatcher.java'),
                    str(ROOT / 'tools/java/TestCW21Loadouts.java')], check=True)
    patched = build / 'CW_21.class'
    subprocess.run(['java', *exports, '-cp', str(build), 'OpenSturmovikAircraftPatcher', str(stock), str(patched), 'CW-21'], check=True)
    helper = build / 'OpenSturmovikCW21LoadoutList.class'
    assert class_address('com.maddox.il2.objects.air.CW_21') == 'F00C363EBB3865E8'
    helper_path = 'Files/' + class_address(HELPER)
    subprocess.run(['java', *exports, '-cp', str(build), 'TestCW21Loadouts', str(patched),
                    str(effective_source), str(helper)], check=True)
    effective_aircraft = parse(effective_bytes)
    registration = [m for m in effective_aircraft.methods if m.name == 'weaponsRegister']
    assert len(registration) == 1 and registration[0].code_blocks == [b'\xb1'], \
        'Effective Aircraft.weaponsRegister is no longer the audited empty method'
    candidates = {'Files/F00C363EBB3865E8': patched, helper_path: helper}
    for address, expected in COCKPITS.items():
        source = donor / address
        assert sha(source.read_bytes()) == expected, str(source)
        candidates['Files/' + address] = source
    resources = donor / '3do/Cockpit/CW-21'
    assert resources.is_dir()
    for source in resources.rglob('*'):
        if source.is_file():
            assert source.resolve().is_relative_to(donor)
            candidates['Files/' + source.relative_to(donor).as_posix()] = source
    assert sha(args.source_archive.read_bytes()) == 'CB6FC40E2ACEFC8F479B00AC5E07FCFAF400633B3882B155AFE7736C6C451DB3'
    with zipfile.ZipFile(args.source_archive) as archive:
        for relative, source in candidates.items():
            if relative in ('Files/F00C363EBB3865E8', helper_path):
                continue
            member = donor.name + '/' + source.relative_to(donor).as_posix()
            assert source.read_bytes() == archive.read(member), member

    # Index existing loose classes; inspect only class-like addresses, not SFS.
    loose = {}
    for source in list((ROOT / 'Files').iterdir()) + list((ROOT / 'Files/com').rglob('*.class')):
        if not source.is_file() or not (re.fullmatch('[0-9A-Fa-f]{16}', source.name) or source.suffix == '.class'):
            continue
        data = source.read_bytes()
        if data[:4] != b'\xca\xfe\xba\xbe':
            continue
        # Some unrelated legacy classes have nonstandard method attributes.
        # Index their identity only; fully parse every dependency actually used.
        c = IDENTITY(source, 'loose')
        loose.setdefault(c.name, []).append((source, sha(data)))
    selected = {parse(s.read_bytes()).name: parse(s.read_bytes()) for k, s in candidates.items() if '/3do/' not in k}
    api, bad_crc = LIB['load_runtime_api'](args.rt_jar)
    origins, missing, ambiguities = {}, set(), set()
    def ensure(name):
        name = name.lstrip('[')
        if name.startswith('L') and name.endswith(';'):
            name = name[1:-1]
        if len(name) == 1 or name in api:
            return
        if name in selected:
            c = selected[name]
            origins[name] = 'candidate'
        elif name in loose:
            options = loose[name]
            if len({v[1] for v in options}) != 1:
                ambiguities.add(name)
            source, _ = options[0]
            c = parse(source.read_bytes(), keep_code=False)
            origins[name] = source.relative_to(ROOT).as_posix()
        else:
            stock_bytes = sfs_class(name)
            if stock_bytes is not None:
                c = parse(stock_bytes, keep_code=False)
                origins[name] = sfs_origin + ':' + name
            else:
                source = args.dump_root / (name + '.class')
                if not source.is_file():
                    missing.add(name)
                    return
                c = parse(source.read_bytes(), keep_code=False)
                origins[name] = '4.09m dump/' + name + '.class'
        api[name] = ApiClass(c.super_name, c.interfaces,
                            {(m.name, m.descriptor) for m in c.fields},
                            {(m.name, m.descriptor) for m in c.methods})
        for parent in [c.super_name, *c.interfaces]:
            if parent:
                ensure(parent)
    failures = []
    for c in selected.values():
        assert c.major <= 47
        for name in c.class_refs | c.descriptor_refs | {c.name}:
            ensure(name)
        for is_method, refs in ((False, c.field_refs), (True, c.method_refs)):
            for owner, name, desc in refs:
                ensure(owner)
                if not LIB['member_exists'](api, owner, name, desc, is_method):
                    failures.append(f'{c.name}: {owner}.{name}{desc}')
        for method in c.methods:
            for code in method.code_blocks:
                failures.extend(LIB['inspect_bytecode'](code))
    ensure('com/maddox/il2/objects/weapons/MGunBrowning50si')
    # Resource integrity: local cockpit texture references must resolve inside
    # the supplied payload (case-insensitive, as on the target Windows system).
    available = {s.relative_to(donor).as_posix().lower() for s in candidates.values() if s.is_relative_to(donor)}
    for source in resources.rglob('*.mat'):
        for match in re.finditer(r'^\s*TextureName\s+(\S+)', source.read_text(encoding='latin1'), re.M):
            ref = match.group(1).replace('\\', '/')
            if ref.startswith('$'):
                continue
            path = (source.parent / ref).resolve()
            if not path.is_relative_to(donor) or path.relative_to(donor).as_posix().lower() not in available:
                failures.append('missing cockpit texture: ' + str(path))
    report = {
        'gameVersion': '4.09m', 'sourceForum': 'https://www.sas1946.com/main/index.php?topic=49201.0',
        'sourceArchive': str(args.source_archive),
        'sourceArchiveSha256': 'CB6FC40E2ACEFC8F479B00AC5E07FCFAF400633B3882B155AFE7736C6C451DB3',
        'sourceStockAircraftSha256': sha(stock.read_bytes()),
        'excludedDonorClasses': ['F00C363EBB3865E8', '723373B2DBC01626'],
        'strategy': 'Four authentic cockpit classes and assets; stock 4.09m CW_21 gains cockpitClass, explicit weaponsList/weaponsMap registration, a CW-21-only unique ArrayList helper and one resolved-audio diagnostic line per aircraft load. Stock FMD, parent, paint and default armament retained; global Aircraft loader unchanged.',
        'registrationContractTest': 'PASS: emitted registration plus actual effective Aircraft.weapons/getWeaponsRegistered bytecode, with API/input doubles; repeated late imports preserve exactly three choices and all slots. Not an in-game or SFS-decryption test.',
        'uniqueListHelper': {'class': HELPER, 'path': helper_path, 'sha256': sha(helper.read_bytes())},
        'effectiveAircraftSha256': sha(effective_bytes),
        'effectiveAircraftSource': effective_origin,
        'effectiveWeaponsRegisterIsEmpty': True,
        'soundDiagnosis': 'Resolved soundName/startStopName/propName logged; no audio gain or physics change; listening test pending',
        'armament': {'default': ['MGunBrowning303ki 300'] * 4,
                     '2x303_2x50': ['MGunBrowning303ki 300'] * 2 + ['MGunBrowning50si 230'] * 2,
                     'none': []},
        'missingClasses': sorted(missing), 'ambiguousClasses': sorted(ambiguities),
        'errors': failures, 'dependencyOrigins': origins,
        'runtimeJarBadCrcCount': len(bad_crc),
        'activeFiles': [{'path': k, 'size': s.stat().st_size, 'sha256': sha(s.read_bytes())} for k, s in sorted(candidates.items())],
        'staticPassed': not (missing or ambiguities or failures), 'runtimeValidation': 'pending',
    }
    audit = ROOT / 'build/cw21-audit/compatibility.json'
    audit.parent.mkdir(parents=True, exist_ok=True)
    audit.write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    if not report['staticPassed']:
        print(json.dumps({k: report[k] for k in ('missingClasses', 'ambiguousClasses', 'errors')}, indent=2))
        return 1
    if args.apply:
        # Refuse overwriting any payload not produced by this verified build.
        for relative, source in candidates.items():
            target = ROOT / relative
            if target.exists() and sha(target.read_bytes()) != sha(source.read_bytes()):
                previous_versions = {
                    '8B97C4067A78619DD19023806AF8A6CE7F736CBE3ED756922DE6071688F4FF2B': 'cw21-before-direct-registration',
                    '2BF3C9625781A7116423BDD18764CAA3AA156C6C76DE20EB24F4A447DB87EE27': 'cw21-before-unique-loadouts',
                }
                previous = sha(target.read_bytes())
                if not (args.replace_previous_cw21 and relative == 'Files/F00C363EBB3865E8'
                        and previous in previous_versions):
                    raise RuntimeError('Different existing file preserved: ' + relative)
                saved = ROOT / 'build/preservation' / previous_versions[previous] / target.name
                saved.parent.mkdir(parents=True, exist_ok=True)
                if saved.exists() and sha(saved.read_bytes()) != previous:
                    raise RuntimeError('Conflicting backup preserved: ' + str(saved))
                if not saved.exists():
                    shutil.copy2(target, saved)
                assert sha(saved.read_bytes()) == previous
        for relative, source in candidates.items():
            target = ROOT / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
            assert sha(target.read_bytes()) == sha(source.read_bytes())
        (ROOT / 'manifests/aircraft/cw21-cockpit-v1.15.json').write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print(f'PASS: {len(selected)} classes, {len(candidates)-len(selected)} cockpit assets; installed={args.apply}; runtime pending.')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
