"""Read-only static availability check for the three modded version profiles.

Uses each profile's own SFS table, never a 4.09m runtime dump for older profiles.
Not a JVM linker: no method-signature, mesh, FM, sound or runtime qualification.
"""
from __future__ import annotations
import argparse
import hashlib
from functools import lru_cache
import importlib.util
import json
import sys
from datetime import datetime, timezone
from pathlib import Path


def load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repository', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--game-root', type=Path, help='Include the test installation common SFS tables and the mapped version payload tables (read-only).')
    parser.add_argument('--all-loose', action='store_true', help='Also report unresolved direct references of all loose classes.')
    args = parser.parse_args()
    repo = args.repository.resolve()
    sfs = load('switcher_sfs', repo / 'tools/Analyze-Sfs.py')
    air = load('switcher_air', repo / 'tools/Audit-AirIniAircraft.py')
    # Only index the loose directory; never call the dump fallback.
    resolver = air.ClassResolver(repo / 'Files', repo / 'WIP/unused-no-dump')
    resolver.index_loose()
    manifest = json.loads((repo / 'manifests/switcher-v1.15.json').read_text('utf-8-sig'))
    common_fingerprints = set()
    common_archives = []
    if args.game_root:
        replaced = {'files.sfs', 'fb_3do19.sfs', 'fb_3do20.sfs', 'fb_maps15.sfs'}
        for source in sorted(args.game_root.glob('*.SFS')):
            if source.name.lower() in replaced:
                continue
            with sfs.SfsArchive(source) as archive:
                common_fingerprints.update(item.fingerprint for item in archive.toc)
            common_archives.append(str(source.resolve()))
    results = []
    for profile in manifest['profiles']:
        if profile['number'] not in (2, 5, 8):
            continue
        registry = repo / '_Game Switcher' / {2: '408m air.ini', 5: '409b air.ini', 8: '409m air.ini'}[profile['number']] / 'Air.ini/air.ini'
        entries = air.parse_air_ini(registry)
        archive_path = repo / '_Game Switcher' / profile['folder'] / 'files.SFS'
        with archive_path.open('rb') as source:
            archive_hash = hashlib.file_digest(source, 'sha256').hexdigest().upper()
        if archive_hash != profile['filesSha256']:
            raise ValueError(f'Unexpected profile SFS hash: {archive_path}')
        with sfs.SfsArchive(archive_path) as archive:
            fingerprints = common_fingerprints | {item.fingerprint for item in archive.toc}
        if args.game_root:
            for item in manifest['payloads'][profile['payload']]:
                if item['file'].lower().endswith('.sfs'):
                    source = repo / '_Game Switcher/Version Payloads' / profile['payload'] / item['file']
                    with sfs.SfsArchive(source) as archive:
                        fingerprints.update(item.fingerprint for item in archive.toc)

        @lru_cache(maxsize=None)
        def available(name):
            if name in resolver.loose:
                return True
            dotted = name.replace('/', '.')
            hashed = sfs.finger_int(ord(char) for char in f'sdw{dotted}cwc2w9e')
            return sfs.finger_string(0, f'cod/{hashed}') in fingerprints

        missing_air = []
        missing_refs = []
        for entry in entries:
            name = air.internal_name(entry.class_token)
            if not available(name):
                missing_air.append({'airKey': entry.key, 'class': name})
                continue
            # Follow loose superclasses and inspect their direct references.
            # SFS class internals are deliberately outside this narrow check.
            seen = set()
            current = name
            while current in resolver.loose and current not in seen:
                seen.add(current)
                summary = sorted(resolver.loose[current], key=lambda item: item.source)[0]
                references = set(summary.class_refs) | set(air.cockpit_names(summary))
                absent = sorted(ref for ref in references if ref.startswith('com/maddox/') and not available(ref))
                if absent:
                    missing_refs.append({'airKey': entry.key, 'owner': current, 'missing': absent})
                current = summary.super_name
        result = {
            'profile': profile['number'], 'version': profile['version'], 'payload': profile['payload'],
            'airEntryCount': len(entries), 'sfsSha256': profile['filesSha256'],
            'missingAircraftClasses': missing_air, 'missingDirectReferencesOfLooseAircraft': missing_refs,
            'classAvailability': 'FAIL' if missing_air else ('WARN' if missing_refs else 'PASS'),
            'scope': 'Files loose classes, profile files.SFS, common SFS and mapped version SFS payload' if args.game_root else 'Files loose classes and this profile files.SFS only; not all engine resource containers',
        }
        results.append(result)
        if args.all_loose:
            result['allLooseUnresolvedReferences'] = []
            for owner, definitions in sorted(resolver.loose.items()):
                summary = sorted(definitions, key=lambda item: item.source)[0]
                absent = sorted(ref for ref in summary.class_refs if ref.startswith('com/maddox/') and not available(ref))
                if absent:
                    result['allLooseUnresolvedReferences'].append({'owner': owner, 'source': summary.source, 'missing': absent})
        print(f"Profile {profile['number']}: {len(entries)} entries, {len(missing_air)} missing aircraft classes, {len(missing_refs)} unresolved direct-reference rows", flush=True)
    report = {
        'dateUtc': datetime.now(timezone.utc).isoformat(), 'gameLaunched': False,
        'method': 'ClassResolver loose index + version-specific SFS fingerprints; no Selector dump',
        'looseClassCount': len(resolver.loose), 'looseParseErrors': resolver.parse_errors,
        'commonArchives': common_archives,
        'profiles': results, 'runtimeQualified': False,
        'missingAircraftClassesFound': any(row['missingAircraftClasses'] for row in results),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    # A generated report is not a successful compatibility check.
    return 1 if report['missingAircraftClassesFound'] else 0


if __name__ == '__main__':
    raise SystemExit(main())
