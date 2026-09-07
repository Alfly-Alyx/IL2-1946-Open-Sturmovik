#!/usr/bin/env python3
"""Reorder the local aircraft lists and labels; never import a foreign air.ini.

An explicit, verified pre-edit backup is mandatory. Dry run by default.
This is an offline content-formatting tool, not a game/installer dependency.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess
import unicodedata

ROOT = Path(__file__).resolve().parent.parent
AIR_ACTIVE = 'Files/com/maddox/il2/objects/air.ini'
AIR408 = '_Game Switchers/408m air.ini/Air.ini/air.ini'
AIR409 = '_Game Switchers/409m air.ini/Air.ini/air.ini'
LABELS = 'Files/i18n/plane_ru.properties'
SWITCHER = 'Open_Sturmovik_Switcher.bat'
BACKUP_HASHES = {
    AIR_ACTIVE: '7B0338B538EB0A72D5108D2A7F23D3BA284237442A5E56142C523AD651CDB7A9',
    AIR408: '8E25257B147AF570C6EFC8044DC34D59C76B9421FB6BBB07B0FB1FA69EFCA7DE',
    AIR409: '7B0338B538EB0A72D5108D2A7F23D3BA284237442A5E56142C523AD651CDB7A9',
    LABELS: 'CC3A933711F92A5D600454B24A15012F21FFEDD44EAC9D44D01A99161C226FCB',
    SWITCHER: '9D920DDB481E137F49F49AD161639190736B21AAC588FEF67A1C4358A2A8404D',
}

# Existing key + documented identity. Names never alter class/skin/mission keys.
ACES = {
    'Durand_Yak-9T': 'Albert Durand Yak-9T',
    'Safonovs_I-16_24': 'Boris Safonov I-16 Type 24',
    'Pokryshkins_MiG-3': 'Alexandre Pokryshkin MiG-3',
    'Pokryshkins_P-39N1': 'Alexandre Pokryshkin P-39N-1',
    'Rechkalovs_P-39Q15': 'Grigori Rechkalov P-39Q-15',
    'Kojedubs_La-7': 'Ivan Kojedub La-7',
    'Graf_Bf-109G-6': 'Hermann Graf Bf-109G-6',
    'Hartmann_Bf-109G-6': 'Erich Hartmann Bf-109G-6',
    'Hans_Rudels_Ju-87G-2': 'Hans-Ulrich Rudel Ju-87G-2',
    'Heppes_Bf-109G-6': 'Aladár Heppes Bf-109G-6',
    'Kovacs_Bf-109G-6': 'Pál Kovács Bf-109G-6',
    'Molnar_Bf-109G-6': 'László Molnár Bf-109G-6',
    'Fabian_Bf-109G-10': 'István Fábián Bf-109G-10',
    'Nowotnys_Me-262A-1a': 'Walter Nowotny Me-262A-1a',
    'Sarvanto_DXXI': 'Jorma Sarvanto D.XXI',
}

# Missing local labels: keep the model/variant already identified by the local
# registry. No invented dates, armaments, performance or new aircraft entries.
MISSING_LABELS = {
    'BlenheimMkIF': 'Bristol Blenheim Mk.IF, 1938',  # local AAA label + maker
    'DXXI_DK': 'Fokker D.XXI DK',
    'DXXI_DU': 'Fokker D.XXI DU',
    'DXXI_SARJA4': 'Fokker D.XXI Sarja 4',
    'MiG-3udfm': 'MiG-3ud FM',
    'MiG-15': 'MiG-15',
    'I-15bis': 'Polikarpov I-15bis',
    'I-15bis_Skis': 'Polikarpov I-15bis (Skis)',
    'U-2NB': 'Polikarpov U-2NB',
    'U-2UT': 'Polikarpov U-2UT',
    'U-2VS(SHKAS)': 'Polikarpov U-2VS (ShKAS)',
    'Yak-1B_Early': 'Yak-1B Early',
    'Yak-1PF': 'Yak-1PF',
    'Yak-1PFLight': 'Yak-1PF Light',
    'Yak-3K': 'Yak-3K',
    'Yak-3VK107(2B20)': 'Yak-3 VK-107 (2xB-20)',
    'Yak-3VK107(3B20)': 'Yak-3 VK-107 (3xB-20)',
    'Yak-7B_late': 'Yak-7B Late',
    'Yak-7UTI': 'Yak-7UTI',
    'Yak-9DD': 'Yak-9DD',
    'Yak-9M_Early': 'Yak-9M Early',
    'Yak-9U_Early': 'Yak-9U Early',
    'AviaB534': 'Avia B-534',
    'G-55': 'Fiat G.55',
    'G-55-Late': 'Fiat G.55 Late',
    'S-328': 'Letov S-328',
    'RE-2000': 'Reggiane Re.2000',
    'SM-79': 'Savoia-Marchetti SM.79',
}

# Abbreviations retained from Alexis's labels, including embedded designations
# (Me-262, FW-190, MiG-3, Yak-9 and DH.98) rather than duplicate prefixes.
MAKER_PREFIXES = [
    ('AerMacchi', r'AerMacchi\s+'), ('Aichi', r'Aichi\s+'),
    ('Arado', r'Arado\s+'), ('Avia', r'Avia\s+'),
    ('Bell', r'Bell\s+'), ('Beriev', r'Beriev\s+'),
    ('Bereznyak-Isayev', r'BI-'), ('Boeing', r'Boeing\s+'),
    ('Brewster', r'Brewster\s+'), ('Bristol', r'Bristol\s+'),
    ('CANT', r'CANT[\s-]'), ('Consolidated', r'Consolidated\s+'),
    ('Curtiss', r'Curtiss(?:-Wright)?\s+'), ('de Havilland', r'DH\.'),
    ('Dornier', r'Dornier\s+'), ('Douglas', r'Douglas\s+'),
    ('Fairey', r'Fairey\s+'), ('Fiat', r'Fiat\s+'),
    ('Fieseler', r'Fieseler\s+'), ('Focke-Wulf', r'FW[\s-]'),
    ('Fokker', r'Fokker\s+'), ('Gloster', r'Gloster\s+'),
    ('Gribovski', r'Gribovski\s+'), ('Grumman', r'Grumman\s+'),
    ('Handley Page', r'Handley Page\s+'), ('Hawker', r'Hawker\s+'),
    ('Heinkel', r'Heinkel\s+'), ('Henschel', r'Henschel\s+'),
    ('Horten-Gotha', r'Horten-Gotha\s+'), ('IAR', r'IAR[\s-]'),
    ('Ilyushin', r'Ilyushin\s+'), ('Junkers', r'Junkers\s+'),
    ('Kawanishi', r'Kawanishi\s+'), ('Kawasaki', r'Kawasaki\s+'),
    ('Lavotchkine', r'Lavotchkine\s+'), ('Letov', r'Letov\s+'),
    ('Lisunov', r'Lisunov\s+'), ('Lockheed', r'Lockheed\s+'),
    ('Messerschmitt', r'Me[\s-]'), ('Mikoyan-Gurevich', r'(?:MiG[\s-])'),
    ('Miles', r'Miles\s+'), ('Mitsubishi', r'Mitsubishi\s+'),
    ('Morane-Saulnier', r'Morane-Saulnier\s+'), ('Nakajima', r'Nakajima\s+'),
    ('Neman', r'Neman\s+'), ('North American', r'N\.A\s+'),
    ('Petliakov', r'Petliakov\s+'), ('Polikarpov', r'Polikarpov\s+'),
    ('PZL', r'PZL(?:/IAR)?\s+'), ('Reggiane', r'Reggiane\s+'),
    ('Republic', r'Republic\s+'), ('RWD', r'RWD[\s-]'),
    ('Savoia-Marchetti', r'Savoia-Marchetti\s+'),
    ('Showa/Nakajima', r'Showa/Nakajima\s+'), ('Sukhoi', r'Sukhoi\s+'),
    ('Tupolev', r'Tupolev\s+'), ('Vickers-Supermarine', r'V\.S\s+'),
    ('Vought', r'Vought\s+'), ('Yakovlev', r'Yak[\s-]'),
    ('Yokosuka', r'Yokosuka\s+'),
]


def sha(data):
    return hashlib.sha256(data).hexdigest().upper()


def ascii_properties(value):
    return ''.join(c if ord(c) < 128 else f'\\u{ord(c):04X}' for c in value)


def parse_air(data):
    lines = data.decode('ascii').splitlines()
    assert lines[0] == '[AIR]'
    rows = [line.split() for line in lines[1:] if line.strip()]
    assert all(len(row) >= 3 and row[1].startswith('air.') and row[2] in ('1', '2') for row in rows)
    assert len({row[0] for row in rows}) == len(rows), 'Duplicate aircraft identifier'
    return rows


def parse_labels(data):
    values, duplicates = {}, []
    for line in data.decode('cp1252').splitlines():
        if not line.strip() or line.lstrip().startswith(('#', '!')):
            continue
        key, value = line.split(None, 1)
        if key in values:
            duplicates.append(key)
        values[key] = value.strip()  # same effective last definition as Properties
    return values, duplicates


def tidy(key, value):
    if key in ACES:
        return ACES[key]
    # Correct only documented maker errors, not historical slot substitutions.
    if key == 'P-400':
        value = value.replace('Curtiss ', 'Bell ', 1)
    if key.startswith('SBD-'):
        value = value.replace('Tupolev ', 'Douglas ', 1)
    if key.startswith(('Ki-21-', 'Ki-46-')):
        value = value.replace('Kawasaki ', 'Mitsubishi ', 1)
    if key.startswith(('Ki-27-', 'Ki-43-', 'Ki-84-')):
        value = value.replace('Kawasaki ', 'Nakajima ', 1)
    if key.startswith('IAR'):
        value = re.sub(r'^Regia\s+I\.?A\.?R\.?\s*', 'IAR ', value)
    if key.startswith('Blenheim') and not value.startswith('Bristol '):
        value = 'Bristol ' + value
    if key == 'J8A':
        value = 'Gloster ' + value
    if key == 'L2D':
        value = 'Showa/Nakajima ' + value
    if key == 'U-2VS':
        value = 'Polikarpov ' + value
    if key in ('BI-1', 'BI-6') and not value.startswith('Bereznyak-Isayev '):
        value = 'Bereznyak-Isayev ' + value
    value = re.sub(r'^Sukho[iï]', 'Sukhoi', value, flags=re.I)
    value = re.sub(r'^Morane[ -]Saulnier', 'Morane-Saulnier', value, flags=re.I)
    value = re.sub(r'^Fokker DXXI\b', 'Fokker D.XXI', value)
    value = re.sub(r'\b(CR|G)\.\s+(\d)', r'\1.\2', value)
    value = value.replace('Me BF-110-G4', 'Me Bf-110G-4')
    value = value.replace('HurricaneM kI aT', 'Hurricane Mk.IaT')
    value = value.replace('HurricaneM kI bT', 'Hurricane Mk.IbT')
    value = value.replace('HurricaneM kI b', 'Hurricane Mk.Ib')
    value = value.replace('MustangIV', 'Mustang Mk.IV')
    value = value.replace('Seafury', 'Sea Fury').replace('Sea-Hurricane', 'Sea Hurricane')
    value = value.replace('Sea-Gladiator', 'Sea Gladiator').replace('Flyingfortress', 'Flying Fortress')
    value = value.replace('Sylver P.', 'Silverplate')
    value = re.sub(r'(?i)\bMK\.?\s*', 'Mk.', value)
    value = re.sub(r'(?i)\b(sarja)\s*(\d)', r'Sarja \2', value)
    value = re.sub(r'(?i)\b(LaGG-3)series(\d+)', r'\1 Series \2', value)
    value = re.sub(r'(?i)\b(I-16)type(\d+)', r'\1 Type \2', value)
    # The variant belongs before the year, not hidden behind it.
    value = re.sub(r',\s*(\d{4})\s*\((\d+) series\)', r' Series \2, \1', value)
    value = value.replace('_Early', ' Early').replace('_Late', ' Late').replace('_Trop', ' Trop')
    value = re.sub(r'\s*,\s*', ', ', value)
    return re.sub(r'\s+', ' ', value).strip()


def roman_value(text):
    values = {'I': 1, 'V': 5, 'X': 10}
    total, last = 0, 0
    for c in reversed(text):
        n = values[c]
        total += -n if n < last else n
        last = max(last, n)
    return total


def natural(value):
    value = value.replace('Mk.', 'Mk')
    # Keep a token boundary: VIII25lbs is Mark 8 / 25lbs, not Mark 825.
    value = re.sub(r'(?<=Mk)([IVX]+)', lambda m: str(roman_value(m[1])) + ' ', value)
    value = unicodedata.normalize('NFKD', value).encode('ascii', 'ignore').decode().casefold()
    # Tagged tokens keep Python comparisons well-defined even for numeric models.
    return tuple((1, int(p)) if p.isdigit() else (0, p) for p in re.split(r'(\d+)', value))


def presentation(key, value):
    if key in ACES:
        return 'Aces', value, value
    matches = [(maker, re.match(pattern, value, re.I)) for maker, pattern in MAKER_PREFIXES]
    matches = [(maker, match) for maker, match in matches if match]
    assert len(matches) == 1, f'Maker unknown or ambiguous: {key}: {value}'
    maker, match = matches[0]
    body = value[match.end():]
    # Shared family identifiers keep export names next to their parent model.
    families = [
        (r'^(P-39|P-400)', 'P-39'), (r'^(B-29|KB_29)', 'B-29'),
        (r'^(H_75|H75|P-36)', 'Hawk 75'),
        (r'^(P-40|Hawk81|Tomahawk)', 'P-40'),
        (r'^(F4F|FM-2|Martlet)', 'F4F'),
        (r'^(TBF|TBM|Avenger)', 'TBF/TBM'),
        (r'^(F51|P-51|Mustang)', 'P-51'),
        (r'^(P-80|F-80|RF-80)', 'F-80'),
        (r'^(F4U|Corsair)', 'F4U'),
        (r'^(Spitfire|SPITXII)', 'Spitfire'),
        (r'^Seafire', 'Seafire'), (r'^SeaHurricane', 'Sea Hurricane'),
        (r'^Hurricane', 'Hurricane'), (r'^Mosquito', 'Mosquito'),
        (r'^U-2TM$', 'Tiger Moth'), (r'^DXXI', 'D.XXI'),
    ]
    model = next((family for pattern, family in families if re.match(pattern, key)), None)
    if model is None:
        # Embedded constructor prefixes need their letter restored for sorting.
        if maker in ('Bereznyak-Isayev', 'Messerschmitt', 'Mikoyan-Gurevich', 'Focke-Wulf', 'RWD', 'Yakovlev') and value[match.end()-1] == '-':
            body = value
        model_match = re.match(r'[A-Za-z]+[.-]?\d+|[A-Za-z.-]+|\d+', body)
        assert model_match, f'Model unknown: {key}: {body}'
        model = model_match[0]
    return maker, model, body


def sort_key(row, labels):
    key = row[0]
    maker, model, body = presentation(key, labels[key])
    if key in ACES:
        return (3, natural(labels[key]), (), (), natural(key))
    # Preserve the side assigned by this exact version, never rewrite army flags.
    # Internal variant identifiers distinguish versions even when the old label
    # hid the series behind a year or placed LF/HF before the Mark number.
    variant = {
        'HurricaneEx': 'HurricaneMkX',
        'SPITXII': 'SpitfireMkXIIclp',
        'SpitfireMkLFXIVE': 'SpitfireMkXIVeLF',
        'SeafireFMkIII': 'SeafireMkIIIF',
        'BF-110-G4': 'Bf-110G-4',
        'P-400': 'P-39 export P-400',
        'KB_29P': 'B-29 tanker KB-29P',
        'B-29-SP': 'B-29 Silverplate',
        'F51': 'P-51D F-51',
        'MustangIII': 'P-51C Mustang MkIII',
        'MustangIV': 'P-51D Mustang MkIV',
        'H_75A2': 'H75-A2',
        'P-36A-3': 'H75-A3',
        'P-36A-4': 'H75-A4',
        'AvengerMkIII': 'TBM-3 Avenger MkIII',
        'P-80A': 'F-80A P-80',
        'RF-80A': 'F-80A RF-80',
        'CR_42': 'CR-42',
        'G_50': 'G-50',
    }.get(key, key)
    variant = variant.replace('DXXI_SARJA', 'DXXI Sarja ')
    variant = re.sub(r'\bSpitfireMk1\b', 'SpitfireMkI', variant)
    return (int(row[2]), natural(maker), natural(model), natural(variant), natural(key))


def render_air(rows, labels):
    result, previous = ['[AIR]', ''], None
    for row in sorted(rows, key=lambda r: sort_key(r, labels)):
        block = (3 if row[0] in ACES else int(row[2]), presentation(row[0], labels[row[0]])[0])
        if previous is not None and block != previous:
            result.append('')
        result.append(f'{row[0]:<30} {row[1]:<34} ' + ' '.join(row[2:]))
        previous = block
    return ('\r\n'.join(result) + '\r\n').encode('ascii')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--backup-root', type=Path, required=True)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--preview-root', type=Path)
    args = parser.parse_args()
    assert subprocess.check_output(['git', '-C', str(ROOT), 'branch', '--show-current'], text=True).strip() == 'v1.15'
    assert Path(subprocess.check_output(['git', '-C', str(ROOT), 'rev-parse', '--show-toplevel'], text=True).strip()).resolve() == ROOT
    originals = {path: (args.backup_root / path).read_bytes() for path in BACKUP_HASHES}
    for path, expected in BACKUP_HASHES.items():
        assert sha(originals[path]) == expected, f'Unverified backup: {path}'
    labels_before, duplicates = parse_labels(originals[LABELS])
    labels = {key: tidy(key, value) for key, value in labels_before.items()}
    for key, value in (MISSING_LABELS | ACES).items():
        if key in MISSING_LABELS:
            assert key not in labels_before, f'Not a missing label: {key}'
        labels[key] = tidy(key, value)
    base_rows = parse_air(originals[AIR409])
    registered = {row[0] for row in base_rows}
    assert registered <= labels.keys(), sorted(registered - labels.keys())
    assert set(ACES) <= registered
    products = {path: render_air(parse_air(originals[path]), labels) for path in (AIR_ACTIVE, AIR408, AIR409)}
    ordered = sorted(base_rows, key=lambda row: sort_key(row, labels))
    label_lines, previous = [], None
    for row in ordered:
        group = 3 if row[0] in ACES else int(row[2])
        if group != previous:
            if previous is not None:
                label_lines.append('')
            label_lines.append('# ' + {1: 'ALLIES - Constructeur / Modele / Variante', 2: 'AXE - Constructeur / Modele / Variante', 3: 'AS - Prenom / Nom / Modele avion'}[group])
        label_lines.append(f'{row[0]:<30} {ascii_properties(labels[row[0]])}')
        previous = group
    extras = sorted(labels.keys() - registered, key=natural)
    if extras:
        label_lines += ['', '# Libelles conserves sans ajouter de nouvel avion a air.ini']
        label_lines += [f'{key:<30} {ascii_properties(labels[key])}' for key in extras]
    products[LABELS] = ('\r\n'.join(label_lines) + '\r\n').encode('ascii')
    switcher = originals[SWITCHER]
    for path in (AIR408, AIR409):
        old, new = BACKUP_HASHES[path].encode(), sha(products[path]).encode()
        assert switcher.count(old) == 1
        switcher = switcher.replace(old, new)
    products[SWITCHER] = switcher
    # Verify complete multisets: no class, key, side, flag or skin token changed.
    for path in (AIR_ACTIVE, AIR408, AIR409):
        assert Counter(map(tuple, parse_air(originals[path]))) == Counter(map(tuple, parse_air(products[path])))
        rows = parse_air(products[path])
        assert rows == sorted(rows, key=lambda r: sort_key(r, labels))
        assert all(r[0] in ACES for r in rows[-sum(r[0] in ACES for r in rows):])
    assert products[AIR_ACTIVE] == products[AIR409]
    new_labels, new_duplicates = parse_labels(products[LABELS])
    assert not new_duplicates and set(labels_before) <= set(new_labels)
    assert all((ROOT / path).read_bytes() in (originals[path], result) for path, result in products.items()), 'Concurrent modification detected'
    if args.preview_root:
        preview = args.preview_root.resolve()
        assert preview.is_relative_to(ROOT / 'build')
        for path, data in products.items():
            target = preview / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
    if args.apply:
        # Bulk mechanical rewrite from the audited mapping above; no runtime work.
        for path, data in products.items():
            (ROOT / path).write_bytes(data)
        assert all((ROOT / path).read_bytes() == data for path, data in products.items())
    report = {
        'status': 'APPLIED' if args.apply else 'PREVIEW',
        'backupRoot': str(args.backup_root),
        'files': {path: {'sha256': sha(data), 'bytes': len(data)} for path, data in products.items()},
        'counts': {path: len(parse_air(products[path])) for path in (AIR_ACTIVE, AIR408, AIR409)},
        'technicalTokensUnchanged': True,
        'aces': ACES,
        'missingLabelsAdded': sorted(set(new_labels) - set(labels_before)),
        'duplicateLabelsConsolidated': duplicates,
        'nonRegisteredLabelsPreserved': extras,
        'groups409': dict(Counter(('Aces' if row[0] in ACES else row[2]) for row in base_rows)),
        'makers409': dict(sorted(Counter(presentation(row[0], labels[row[0]])[0] for row in base_rows).items())),
    }
    if args.apply:
        (ROOT / 'manifests/aircraft/presentation-v1.15.json').write_text(
            json.dumps(report, ensure_ascii=True, indent=2) + '\n', encoding='ascii')
    if args.preview_root:
        (preview / 'report.json').write_text(json.dumps(report, ensure_ascii=True, indent=2) + '\n', encoding='ascii')
    print(json.dumps(report, ensure_ascii=True, indent=2))


if __name__ == '__main__':
    main()
