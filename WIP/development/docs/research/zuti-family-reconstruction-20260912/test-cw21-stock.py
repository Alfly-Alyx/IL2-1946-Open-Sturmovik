"""Execute the existing CW-21 loader contract against exact profile SFS classes.

Uses only an auto-cleaned temporary compilation directory and the selected JSON
output. No game, installer application or write to Files is performed.
"""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import tempfile


def sha(data):
    return hashlib.sha256(data).hexdigest().upper()


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--repository-root', required=True, type=Path)
    ap.add_argument('--output', required=True, type=Path)
    args = ap.parse_args()
    root = args.repository_root.resolve()
    folder = root/'docs/research/zuti-family-reconstruction-20260912'
    plan = json.loads((folder/'retirement-plan.json').read_text(encoding='utf-8'))
    sfs = runpy.run_path(str(root/'tools/Analyze-Sfs.py'), run_name='cw21_sfs')
    aircraft = root/'Files/F00C363EBB3865E8'
    helper = root/'Files/7F567DAABB958052'
    exports = ['--add-exports', 'java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED',
               '--add-exports', 'java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED']
    tests = []
    with tempfile.TemporaryDirectory(prefix='open-sturmovik-cw21-stock-') as temp:
        build = Path(temp)
        subprocess.run(['javac', *exports, '-d', str(build), str(root/'tools/java/TestCW21Loadouts.java')], check=True)
        for version, archive_info in plan['source_archives'].items():
            source = Path(archive_info['archive'])
            assert sha(source.read_bytes()).lower() == archive_info['archive_sha256']
            with sfs['SfsArchive'](source) as archive:
                data = archive.extract_class('com.maddox.il2.objects.air.Aircraft')
            assert sha(data) == '079760CADF85DA3CB26856C0D5B541EBC51E017A450F1648B27426D8E00D7BE3'
            extracted = build/(version+'-Aircraft.class')
            extracted.write_bytes(data)
            result = subprocess.run(['java', *exports, '-cp', str(build), 'TestCW21Loadouts',
                str(aircraft), str(extracted), str(helper)], text=True, capture_output=True, check=True)
            assert result.stdout.startswith('PASS:'), result.stdout
            tests.append({'version': version, 'archive': str(source), 'archive_sha256': sha(source.read_bytes()),
                'aircraft_class_sha256': sha(data), 'result': result.stdout.strip()})
    output = {'date': '2026-09-12', 'scope': 'Actual Aircraft loader bytecode, active CW-21 registration and helper; API/input doubles, no in-game test.',
        'cw21_class_sha256': sha(aircraft.read_bytes()), 'helper_sha256': sha(helper.read_bytes()),
        'loose_aircraft_present': (root/'Files/4B598398AD1D180C').exists(), 'tests': tests}
    args.output.write_text(json.dumps(output, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print('PASS: three stock SFS loader contracts, three unique loadouts, exact guns and ammunition.')


if __name__ == '__main__':
    main()
