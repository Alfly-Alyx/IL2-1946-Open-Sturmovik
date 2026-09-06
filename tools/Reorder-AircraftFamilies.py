#!/usr/bin/env python3
"""Apply Alexis's family/evolution order to his existing, already named lists.

No aircraft, technical field or displayed name is changed. Dry run by default.
Family branches stay contiguous; this is not a global sort by service year.
Unknown mod subvariants stay with their parent rather than receiving fake dates.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
import re
import runpy
import subprocess

BASE = runpy.run_path(str(Path(__file__).with_name('Update-AircraftPresentation.py')))
ROOT = BASE['ROOT']
AIR_PATHS = [BASE['AIR_ACTIVE'], BASE['AIR408'], BASE['AIR409']]
LABELS, SWITCHER = BASE['LABELS'], BASE['SWITCHER']
parse_air, parse_labels, sha, natural = (BASE[n] for n in ('parse_air', 'parse_labels', 'sha', 'natural'))
ACES = BASE['ACES']
EXPECTED = {
    AIR_PATHS[0]: '71284FCFC79C95BCFEC8B4C0D09E676D710334246000D42FF0DDDF751DDD012E',
    AIR_PATHS[1]: 'FE788D676046D291A8F888E19218D628F8C435DBCBF59102401B0CF08C41D7C8',
    AIR_PATHS[2]: '71284FCFC79C95BCFEC8B4C0D09E676D710334246000D42FF0DDDF751DDD012E',
    LABELS: 'BB0A1C0DE951CBD0AD8306276F93D2A3F167FCCAE46A61DFB4EE43D640156C49',
    SWITCHER: 'A89F270FD08F1CA1120C28A02265511A7ED206A586D77FF5F83CD7B28FFBB3B5',
}

# Editorial family sequences. Descendants follow their parent block even when
# parallel branches overlap in calendar time. Independent lines retain a stable
# order; these lists do not purport to date every experimental mod variant.
FAMILY_ORDER = {
    'Bell': ['P-39', 'P-63'],
    'Boeing': ['P-26', 'B-17', 'B-29'],
    'Brewster': ['Buffalo'],
    'Bristol': ['Blenheim', 'Beaufighter'],
    'Consolidated': ['PBY/PBN', 'B-24'],
    'Curtiss': ['Hawk 75', 'P-40', 'CW-21'],
    'de Havilland': ['Tiger Moth', 'Mosquito'],
    'Douglas': ['C-47', 'A-20', 'SBD'],
    'Fairey': ['Swordfish', 'Battle'],
    'Gloster': ['Gladiator', 'Sea Gladiator'],
    'Grumman': ['F4F', 'F6F', 'TBF/TBM', 'F9F Panther', 'F9F Cougar'],
    'Hawker': ['Hurricane', 'Sea Hurricane', 'Typhoon', 'Tempest', 'Sea Fury'],
    'Ilyushin': ['DB-3', 'IL-4', 'IL-2', 'IL-10'],
    'Lavotchkine': ['LaGG-3', 'La-5', 'La-7'],
    'Lockheed': ['P-38', 'F-80', 'P2V'],
    'Mikoyan-Gurevich': ['MiG-3', 'I-250', 'MiG-9', 'MiG-15'],
    'North American': ['B-25', 'P-51', 'F-86'],
    'Petliakov': ['Pe-8', 'Pe-2', 'Pe-3'],
    'Polikarpov': ['U-2', 'I-15', 'I-153', 'I-16', 'I-185'],
    'PZL': ['P.11', 'P.24', 'P-37'],
    'Republic': ['P-47', 'F-84 Thunderjet', 'F-84 Thunderstreak'],
    'Tupolev': ['TB-3', 'SB', 'Tu-2'],
    'Vickers-Supermarine': ['Spitfire', 'Seafire'],
    'Yakovlev': ['Yak-1', 'Yak-7', 'Yak-9', 'Yak-3', 'Yak-15'],
    'AerMacchi': ['MC.200', 'MC.202', 'MC.205'],
    'Fiat': ['CR.32', 'CR.42', 'G.50', 'G.55'],
    'Focke-Wulf': ['FW-200', 'FW-189', 'FW-190', 'Ta-152', 'Ta-183'],
    'Heinkel': ['He-111', 'He-219', 'He-162', 'Lerche'],
    'Henschel': ['Hs-123', 'Hs-129'],
    'IAR': ['80', '81'],
    'Junkers': ['Ju-52', 'Ju-87', 'Ju-88'],
    'Kawasaki': ['Ki-61', 'Ki-100'],
    'Messerschmitt': ['Bf-109', 'Bf-110', 'Me-210', 'Me-410', 'Me-321', 'Me-323', 'Me-163', 'Me-262'],
    'Morane-Saulnier': ['406', '410', 'MM'],
}

ALIASES = [
    (r'^SeaFury', 'Sea Fury'), (r'^SeaGladiator', 'Sea Gladiator'),
    (r'^(Gladiator|J8A)', 'Gladiator'),
    (r'^(F2A|Buffalo|B-239)', 'Buffalo'),
    (r'^(PBY|PBN)', 'PBY/PBN'), (r'^SBD-', 'SBD'),
    (r'^F6F', 'F6F'), (r'^F9F2', 'F9F Panther'), (r'^XF9F6', 'F9F Cougar'),
    (r'^P2V', 'P2V'), (r'^F84G', 'F-84 Thunderjet'), (r'^F84F', 'F-84 Thunderstreak'),
    (r'^Il-4', 'IL-4'),
]

# Explicit subseries where alphabetical/numerical order is misleading. These
# are existing identifiers, never names imported from another air.ini.
VARIANT_SEQUENCES = [
    ['HurricaneMkIearly', 'HurricaneMkI', 'HurricaneMkILate', 'HurricaneMkIaT',
     'HurricaneMkIb', 'HurricaneMkIbT', 'HurricaneMkIIa', 'HurricaneMkIIb',
     'HurricaneMkIIbT', 'HurricaneMkIIbMod', 'HurricaneMkIIc', 'HurricaneMkIId', 'HurricaneEx'],
    ['P-39D1', 'P-39D2', 'P-400', 'P-39N1', 'P-39Q-1', 'P-39Q-10'],
    ['B-239', 'F2A-2', 'BuffaloMkI'],
    ['PBY-5', 'PBN-1'],
    ['Hawk81A-2', 'P-40B', 'P-40Breco', 'TomahawkMkIIa', 'P-40C',
     'TomahawkMkIIb', 'P-40E', 'P-40E-M-105', 'P-40M'],
    ['F4F-3', 'MartletMkII', 'F4F-4', 'FM-2'],
    ['TBF-1', 'TBM1', 'TBF-1C', 'TBM-3', 'AvengerMkIII'],
    ['P-80A', 'F-80A', 'RF-80A'],
    ['P-51B-NA', 'P-51C-NT', 'MustangIII', 'P-51D-5NT', 'P-51D',
     'P-51D2', 'P-51D-20NA', 'MustangIV', 'F51'],
    ['P-47D-10', 'P-47D-22', 'P-47D-27', 'P-47D'],
    ['F4U-1A', 'CorsairMkI', 'CorsairMkII', 'F4U-2', 'F4U-1D',
     'CorsairMkIV', 'F4U-1C', 'F4U-5N'],
    ['Il-2_1940_Early', 'Il-2_1940_Late', 'Il-2_1941_Early', 'Il-2_1941_Late',
     'Il-2M_Early', 'Il-2M_Late', 'Il-2I', 'Il-2I_DZZMod', 'Il-2_3',
     'Il-2_M3', 'Il-2T', 'Il-2T_DZZMod'],
    ['LaGG-3series1', 'LaGG-3series4', 'LaGG-3series11', 'LaGG-3series29',
     'LaGG-3series35', 'LaGG-3IT', 'LaGG-3series66', 'LaGG-3RD'],
    ['La-5', 'La-5F_Early', 'La-5F', 'La-5FN'],
    ['MiG-9protoF-2', 'MiG-9FS'],
    ['Yak-7UTI', 'Yak-7A', 'Yak-7B', 'Yak-7BPF', 'Yak-7B_late'],
    ['Yak-9', 'Yak-9D', 'Yak-9RLR_DZZMod', 'Yak-9T', 'Yak-9M_Early',
     'Yak-9M', 'Yak-9K', 'Yak-9B', 'Yak-9DD', 'Yak-9U_Early', 'Yak-9U', 'Yak-9UT'],
    ['Ki-61-I-Ko', 'Ki-61-I-Otsu', 'Ki-61-I-Hei'],
    ['Ki-46-Recce', 'Ki-46-Otsu', 'Ki-46-Otsu-Hei'],
    ['Ju-87B-2', 'Ju-87R-2_DZZMod', 'Ju-87D-3', 'Ju-87D-5', 'Ju-87G-1'],
]
VARIANT_RANK = {key: rank for sequence in VARIANT_SEQUENCES for rank, key in enumerate(sequence)}
assert sum(map(len, VARIANT_SEQUENCES)) == len(VARIANT_RANK)


def family(key, label):
    maker, model, body = BASE['presentation'](key, label)
    model = next((name for regex, name in ALIASES if re.match(regex, key)), model)
    return maker, model, body


def variant_key(key, label, model):
    if key in VARIANT_RANK:
        return (0, VARIANT_RANK[key], (), 0, ())
    variant = key
    # Normalize encoded spellings without renaming the aircraft identifiers.
    variant = variant.replace('SPITXII', 'SpitfireMkXIIclp')
    variant = variant.replace('SpitfireMkLFXIVE', 'SpitfireMkXIVeLF')
    variant = variant.replace('SeafireFMkIII', 'SeafireMkIIIF')
    variant = variant.replace('Fw-190A-5165ATA', 'Fw-190A-5-165ATA')
    variant = variant.replace('La-73xB20', 'La-7-3xB20')
    variant = variant.replace('BF-110-G4', 'Bf-110G-4')
    # The G-14 preceded the G-10. Keep each block together, including AS/MG mods.
    if model == 'Bf-109':
        variant = variant.replace('Bf-109G-14', 'Bf-109G-09')
    stage = -1 if re.search('early', variant, re.I) else 1 if re.search('late', variant, re.I) else 0
    stem = re.sub(r'[_ -]?(?:early|late)', '', variant, flags=re.I)
    mark = re.search(r'Mk([IVX]+|\d+)', stem)
    if mark:
        number = int(mark[1]) if mark[1].isdigit() else BASE['roman_value'](mark[1])
        # Operational introduction: Mk IX (1942) before VIII (1943).
        if model == 'Spitfire':
            number = {1: 1, 2: 2, 5: 3, 9: 4, 8: 5, 12: 6, 14: 7}[number]
        suffix = stem[mark.end():]
        return (1, number, natural(suffix), stage, natural(key))
    return (2, 0, natural(stem), stage, natural(key))


def sort_key(row, labels):
    key = row[0]
    if key in ACES:
        return (3, natural(labels[key]), 0, (), ())
    maker, model, body = family(key, labels[key])
    sequence = FAMILY_ORDER.get(maker, [])
    rank = sequence.index(model) if model in sequence else len(sequence)
    return (int(row[2]), natural(maker), rank, natural(model), variant_key(key, labels[key], model))


def render(rows, labels):
    result, previous = ['[AIR]'], None
    for row in sorted(rows, key=lambda r: sort_key(r, labels)):
        key = row[0]
        block = ('Aces',) if key in ACES else (row[2], *family(key, labels[key])[:2])
        if block != previous:
            result.append('')
        result.append(f'{key:<30} {row[1]:<34} ' + ' '.join(row[2:]))
        previous = block
    return ('\r\n'.join(result) + '\r\n').encode('ascii')


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--backup-root', type=Path, required=True)
    p.add_argument('--apply', action='store_true')
    args = p.parse_args()
    assert subprocess.check_output(['git', '-C', str(ROOT), 'branch', '--show-current'], text=True).strip() == 'v1.15'
    assert Path(subprocess.check_output(['git', '-C', str(ROOT), 'rev-parse', '--show-toplevel'], text=True).strip()).resolve() == ROOT
    originals = {path: (args.backup_root / path).read_bytes() for path in EXPECTED}
    for path, data in originals.items():
        assert sha(data) == EXPECTED[path], f'Unexpected backup: {path}'
    labels, duplicates = parse_labels(originals[LABELS])
    assert not duplicates
    rows = parse_air(originals[AIR_PATHS[0]])
    assert len(rows) == 535
    known = {r[0] for r in rows}
    assert set(VARIANT_RANK) <= known, sorted(set(VARIANT_RANK) - known)
    products = {path: render(parse_air(originals[path]), labels) for path in AIR_PATHS}
    order = sorted(rows, key=lambda r: sort_key(r, labels))
    label_lines, previous = [], None
    for row in order:
        key = row[0]
        block = ('Aces',) if key in ACES else (row[2], *family(key, labels[key])[:2])
        if block != previous:
            if previous is not None:
                label_lines.append('')
            label_lines.append('# ' + ('AS - Prenom / Nom / Modele avion' if key in ACES
                else ('ALLIES' if row[2] == '1' else 'AXE') + ' - ' + ' / '.join(block[1:])))
        label_lines.append(f'{key:<30} {labels[key]}')
        previous = block
    extras = sorted(set(labels) - known)
    label_lines += ['', '# Libelles conserves hors air.ini'] + [f'{k:<30} {labels[k]}' for k in extras]
    products[LABELS] = ('\r\n'.join(label_lines) + '\r\n').encode('ascii')
    switcher = originals[SWITCHER]
    for path in AIR_PATHS[1:]:
        old, new = EXPECTED[path].encode(), sha(products[path]).encode()
        assert switcher.count(old) == 1
        switcher = switcher.replace(old, new)
    products[SWITCHER] = switcher
    for path in AIR_PATHS:
        before, after = parse_air(originals[path]), parse_air(products[path])
        assert Counter(map(tuple, before)) == Counter(map(tuple, after))
        assert len({r[0] for r in after}) == len(after)
        assert [r for r in before if r[0] in ACES] == [r for r in after if r[0] in ACES]
    new_labels, duplicates = parse_labels(products[LABELS])
    assert new_labels == labels and not duplicates, 'An aircraft name changed'
    assert products[AIR_PATHS[0]] == products[AIR_PATHS[2]]
    hawker = [family(r[0], labels[r[0]])[1] for r in order if family(r[0], labels[r[0]])[0] == 'Hawker']
    assert list(dict.fromkeys(hawker)) == FAMILY_ORDER['Hawker']
    positions = {r[0]: i for i, r in enumerate(order)}
    for first, second in [('HurricaneMkIearly', 'HurricaneMkI'), ('HurricaneMkI', 'HurricaneMkILate'),
                          ('SpitfireMkXIVC', 'SeafireMkI'), ('SpitfireMkIXc', 'SpitfireMkVIII'),
                          ('MosquitoFBMkVI', 'MosquitoBMkXVI'), ('Bf-109G-14', 'Bf-109G-10'),
                          ('LaGG-3series66', 'La-5'), ('Yak-9', 'Yak-3'),
                          ('Fw-190A-5165ATA', 'Fw-190A-6'), ('Ki-61-I-Ko', 'Ki-61-I-Hei')]:
        assert positions[first] < positions[second], (first, second)
    assert all((ROOT / path).read_bytes() in (originals[path], value) for path, value in products.items()), 'Concurrent change preserved'
    report = {
        'status': 'APPLIED' if args.apply else 'PREVIEW', 'backupRoot': str(args.backup_root),
        'policy': 'Manufacturer, contiguous evolutionary family blocks, parent variants then naval derivatives; no global year sort',
        'files': {path: {'sha256': sha(data), 'bytes': len(data)} for path, data in products.items()},
        'countsBeforeAfter': {path: [len(parse_air(originals[path])), len(parse_air(products[path]))] for path in AIR_PATHS},
        'technicalTokensUnchanged': True, 'displayNamesUnchanged': True, 'acesOrderUnchanged': True,
        'familyOrder': FAMILY_ORDER, 'variantSequences': VARIANT_SEQUENCES,
        'runtimeValidation': 'pending; game not launched by this tool',
    }
    if args.apply:
        previous_report = json.loads((args.backup_root / 'manifests/aircraft/presentation-v1.15.json').read_text())
        previous_report['files'] = report['files']
        previous_report['evolutionOrderReport'] = 'manifests/aircraft/family-evolution-v1.15.json'
        for path, data in products.items():
            (ROOT / path).write_bytes(data)
        assert all((ROOT / path).read_bytes() == data for path, data in products.items())
        (ROOT / 'manifests/aircraft/family-evolution-v1.15.json').write_text(json.dumps(report, indent=2) + '\n', encoding='ascii')
        (ROOT / 'manifests/aircraft/presentation-v1.15.json').write_text(json.dumps(previous_report, indent=2) + '\n', encoding='ascii')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
