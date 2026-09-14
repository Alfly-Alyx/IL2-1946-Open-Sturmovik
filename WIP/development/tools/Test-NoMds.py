#!/usr/bin/env python3
"""Verify the recorded MDS removal against the actual distribution (read-only).

History and reconstruction tools can mention MDS. Runtime classes cannot contain
Zuti constants; retired payloads must be absent, cleaned payloads hash-identical.
The SFS family/linkage proof is reproduced by the separate family audit.
"""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--content-root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--manifest-root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    root = args.content_root.resolve()
    spec = args.manifest_root.resolve()
    failures = []
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest().upper()
    manifest = json.loads((spec/'manifests/mods/retired-zuti-mds-v1.15.json').read_text(encoding='utf-8-sig'))
    for entry in manifest['entries']:
        path = root/entry['path']
        if entry['action'] == 'delete':
            if path.exists():
                failures.append('Retired file is present: '+entry['path'])
        elif entry.get('runtime', True):
            accepted = {entry['afterSha256'].upper(), *(h.upper() for h in entry.get('allowedRuntimeSha256', []))}
            if not path.is_file() or sha(path) not in accepted:
                failures.append('Cleaned file differs: '+entry['path'])
    for entry in manifest['preservedRuntime']:
        path = root/entry['path']
        if not path.is_file() or sha(path) != entry['sha256'].upper():
            failures.append('Preserved dependency differs: '+entry['path'])
    for entry in manifest['profileArchives']:
        path = root/entry['path']
        if not path.is_file() or sha(path) != entry['sha256'].upper():
            failures.append('Verified stock profile archive differs: '+entry['path'])

    # Native directory enumeration includes ignored and untracked runtime files.
    listing = subprocess.run(['rg','--files','--hidden','--no-ignore',str(root/'Files')],capture_output=True,check=True)
    classes = 0
    for encoded in listing.stdout.splitlines():
        path = Path(encoded.decode('utf-8'))
        if not (path.suffix.lower() == '.class' or re.fullmatch(r'[0-9A-Fa-f]{16}',path.name)):
            continue
        data = path.read_bytes()
        if data[:4] != bytes.fromhex('CAFEBABE'):
            continue
        classes += 1
        if b'zuti' in data.lower():
            failures.append('Runtime class still contains Zuti: '+str(path.relative_to(root)))
    if classes < 1000:
        failures.append('Incomplete runtime class scan: '+str(classes))
    mission_scan = subprocess.run(['rg','-l','--hidden','--no-ignore','-i',r'^\s*(\[MDS|Zuti\w+)','-g','*.mis',
                                   str(root/'Missions'),str(root/'Files')],capture_output=True)
    if mission_scan.returncode not in (0,1):
        failures.append('Mission scan failed: '+mission_scan.stderr.decode('utf-8',errors='replace'))
    elif mission_scan.stdout:
        failures.extend('Residual MDS mission data: '+p.decode('utf-8') for p in mission_scan.stdout.splitlines())
    labels = subprocess.run(['rg','-l','--hidden','--no-ignore','-i',r'^\s*mds[._]','-g','*.properties',
                             str(root/'Files/i18n'),str(root/'_Game Switcher')],capture_output=True)
    if labels.returncode not in (0,1):
        failures.append('MDS labels scan failed: '+labels.stderr.decode('utf-8',errors='replace'))
    elif labels.stdout:
        failures.extend('Residual MDS labels: '+p.decode('utf-8') for p in labels.stdout.splitlines())
    result = {'result':'FAIL' if failures else 'PASS','runtimeClassesScanned':classes,
              'retiredPathsChecked':sum(e['action']=='delete' for e in manifest['entries']),
              'cleanedPathsChecked':sum(e['action']=='replace' for e in manifest['entries']),
              'profileArchivesChecked':len(manifest['profileArchives']),
              'failures':failures,
              'limit':'Static removal checks; actual game startup and flight are not exercised.'}
    rendered=json.dumps(result,ensure_ascii=True,indent=2)+'\n'
    if args.report:
        args.report.parent.mkdir(parents=True,exist_ok=True)
        args.report.write_text(rendered,encoding='utf-8')
    print(rendered,end='')
    return 1 if failures else 0


if __name__ == '__main__':
    sys.exit(main())
