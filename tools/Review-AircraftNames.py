#!/usr/bin/env python3
"""Review v1.15 display names without rewriting aircraft IDs or classes.

Requires the verified pre-review backup. Dry run by default. The historical
sorting builders must NOT be replayed to apply this later presentation pass.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import runpy
import subprocess

ROOT = Path(__file__).resolve().parent.parent
BASE = runpy.run_path(str(ROOT / 'tools/Update-AircraftPresentation.py'))
SFS = runpy.run_path(str(ROOT / 'tools/Analyze-Sfs.py'))
CLASS = runpy.run_path(str(ROOT / 'tools/Audit-AirIniAircraft.py'))['parse_class']
LABELS = BASE['LABELS']
AIR_PATHS = [BASE[k] for k in ('AIR_ACTIVE', 'AIR408', 'AIR409')]
EXPECTED = {
    LABELS: 'A3DC34A92F76E531CFC4F60D4D5A0BB6E38A158EF9BB6299A6D78C270FD73B17',
    AIR_PATHS[0]: '3ABEB3E3EB136AD3C1E1825118D06EA2C293D10F8C7E442BA5A599C8D6AAB508',
    AIR_PATHS[1]: 'B25B048B2FB9D434BC31A47F74430143A169DB1887A2C9B09405F627423197EE',
    AIR_PATHS[2]: '3ABEB3E3EB136AD3C1E1825118D06EA2C293D10F8C7E442BA5A599C8D6AAB508',
    BASE['SWITCHER']: '93C33B0F0589A7C3E7DFE21F25B2AF99B8E1362D3CEE518F75464C46DB701061',
}

# Exact presentation choices, never a conversion from an internal key alone.
# Years are copied from the previous display name and not historically redated.
OVERRIDES = {
    'F2A-2': 'Brewster F2A-2 Buffalo',
    'PBN-1': 'Consolidated PBN-1 Nomad',
    'Li-2': 'Douglas Li-2',
    'L2D': 'Douglas L2D',
    'Go-229A-1': 'Horten Go-229A-1',
    'AviaB534': 'Avia B-534 Serie IV',
    'G-55': 'Fiat G.55 Serie I Early Centauro',
    'G-55-Late': 'Fiat G.55 Serie I Late Centauro',
    'H_75A2': 'Curtiss Model 75A-2 Hawk',
    'P-36A-3': 'Curtiss Model 75A-3 Hawk',
    'P-36A-4': 'Curtiss Model 75A-4 Hawk',
    'Hawk81A-2': 'Curtiss Model 81A-2 Hawk',
    'MosquitoBMkXVI': 'DH.98 Mosquito B.Mk.XVI',
    'SeaGladiatorMkII': 'Gloster Sea Gladiator Mk.II',
    'MartletMkII': 'Grumman Martlet Mk.II',
    'FM-2': 'Grumman FM-2 Wildcat',
    'TBM1': 'Grumman TBM-1 Avenger',
    'TBM-3': 'Grumman TBM-3 Avenger',
    'AvengerMkIII': 'Grumman Avenger Mk.III',
    'F9F2_Panther': 'Grumman F9F-2 Panther',
    'XF9F6_Cougar': 'Grumman XF9F-6 Cougar',
    'HurricaneMkIIbT': 'Hawker Hurricane Mk.IIbT',
    'TyphoonMkIBLate': 'Hawker Typhoon Mk.Ib Late',
    'TempestMkV11Lbs': 'Hawker Tempest Mk.V (11 lbs)',
    'TempestMkV13Lbs': 'Hawker Tempest Mk.V (13 lbs)',
    'Il-2_1941_Late': 'Ilyushin Il-2 (field mod.)',
    'Il-2M_Early': 'Ilyushin Il-2M (first series)',
    'Il-2M_Late': 'Ilyushin Il-2M (later series)',
    'P-80A': 'Lockheed P-80A Shooting Star',
    'P2V-5': 'Lockheed P2V-5 Neptune',
    'P-51D': 'N.A P-51D Mustang (mod P-51D)',
    'P-51D2': 'N.A P-51D Mustang (mod P-51D2)',
    'F84G1_ThunderJet': 'Republic F-84G Thunderjet (mod G1)',
    'F84G3_ThunderJet': 'Republic F-84G Thunderjet (mod G3)',
    'F84F1_Thunderstreak': 'Republic F-84F Thunderstreak',
    'I-153_2SHKAS_BS': 'Polikarpov I-153 (2xShKAS + BS)',
    'I-16type24orig': 'Polikarpov I-16 Type 24 (Original)',
    'SpitfireMkIbFR': 'V.S Spitfire FR Mk.Ib',
    'SpitfireMkVc': 'V.S Spitfire Mk.Vc (2xH)',
    'SpitfireMkVc4xH': 'V.S Spitfire Mk.Vc (4xH)',
    'SpitfireMkVcFB': 'V.S Spitfire FB Mk.Vc',
    'SpitfireMkVcFB4xH': 'V.S Spitfire FB Mk.Vc (4xH)',
    'SpitfireMkVcLF': 'V.S Spitfire LF Mk.Vc',
    'SpitfireMkVcLF4xH': 'V.S Spitfire LF Mk.Vc (4xH)',
    'SpitfireMkVcLFCLP': 'V.S Spitfire LF Mk.Vc (CW)',
    'SpitfireMkIXcLF': 'V.S Spitfire LF Mk.IXc',
    'SpitfireMkVIII25lbs': 'V.S Spitfire Mk.VIII (25 lbs)',
    'SpitfireMkVIIICLP': 'V.S Spitfire Mk.VIII (CW)',
    'SpitfireMkVIIICLPFB': 'V.S Spitfire FB Mk.VIII (CW)',
    'SpitfireMkVIIIFB': 'V.S Spitfire FB Mk.VIII',
    'SpitfireMkVIIIHF': 'V.S Spitfire HF Mk.VIII',
    'SeafireMkII4xH': 'V.S Seafire Mk.II (4xH)',
    'SeafireMkII45': 'V.S Seafire Mk.II (45)',
    'SeafireMkII50': 'V.S Seafire Mk.II (50)',
    'CorsairMkIV': 'Vought Corsair Mk.IV',
    'Yak-7BPF': 'Yak-7B PF',
    'CANT1007': 'CANT Z.1007bis',
    'CANT1007t': 'CANT Z.1007 (Torp)',
    'IAR80early': 'IAR 80 Early',
    'IAR81Cnew': 'IAR 81C (New)',
    'He-162B': 'Heinkel He-162B',
    'Ju-52/3mg4e': 'Junkers Ju-52/3mg4e',
    'Ki-46-Otsu': 'Mitsubishi Ki-46-III Kai Otsu',
    'Ki-46-Otsu-Hei': 'Mitsubishi Ki-46-III Kai Otsu-Hei',
    'MS406': 'Morane-Saulnier MS.406',
    'MS410': 'Morane-Saulnier MS.410',
}

# These suffixes identify a mod, not a historically verified production block.
UNRESOLVED = {
    'P-51D': 'Mod-specific identity; mesh D-20NA is not proof of its production block. Keep mod ID explicit.',
    'P-51D2': 'D2 is an internal mod ID, not an established P-51D-2 production block. Mesh D-5NT alone is insufficient.',
    'F84G1_ThunderJet': 'G1 is retained as a mod ID, not asserted as a G-1 block; dump uses a surrogate He-162C FMD.',
    'F84G3_ThunderJet': 'G3 is retained as a mod ID, not asserted as a G-3 block; special weapon references do not prove a block.',
    'MS-Morko': 'Legacy label MMorko 318 retained: model versus individual serial not established locally.',
    'MsMorko410': 'Legacy MMorko 410 retained: exact historical conversion designation not established.',
    'SeafireMkII45': 'Token 45 retained without inventing an engine or subtype interpretation.',
    'SeafireMkII50': 'Token 50 retained without inventing an engine or subtype interpretation.',
    'Bf-109G-10_Erla2': 'Token Erla2 belongs to the mod; no invented historical suffix.',
    'Bf-109G-10_ErlaC3_45': 'C3/45 tokens preserved; historical meaning not independently established.',
    'Bf-109G-10MG': 'MG mod suffix retained without expansion.',
    'Bf-109G-14MG': 'MG mod suffix retained without expansion.',
    'MC-205_IIIS': 'S suffix retained from the local mod; not recast as a standard C.205V.',
    'P-80A': 'Local class/FMD use P-80A; Aircraft Guide and SAS also call the same slot YP-80. P-80A is a local identity, not a certified prototype/production attribution.',
    'XF9F6_Cougar': 'Class and mesh identify XF9F6; FMD is F9F2. XF9F-6 existed historically, but this mod is not certified as an exact prototype. Old dump fails javap; loose constant pool is readable.',
    'Bf-109E-1_Late': 'Conflict: local key/OS1.1 label say Late, class BF_109E1early and SAS inventory say Early, mesh/FMD reference E-4. Preserve local label; do not invent an official subtype.',
    'IAR80early': 'Class/FMD suffix A conflicts with mesh/OS1.1/SAS Early label; old dump registers four weapon hooks. Do not rename IAR 80A based on class token alone.',
}

OBSERVE_KEYS = ['P-51D', 'P-51D2', 'P-80A', 'F84G1_ThunderJet', 'F84G3_ThunderJet',
                'F84F1_Thunderstreak', 'MartletMkII', 'MosquitoBMkXVI', 'SeaGladiatorMkII',
                'He-162B', 'Ju-52/3mg4e', 'Ki-46-Otsu', 'Ki-46-Otsu-Hei', 'XF9F6_Cougar']

EARLY_LATE = {
    **dict.fromkeys(['G-55', 'G-55-Late'], 'Guide_409m p12: both Serie I; Late lifts the engine limitation, not a new Serie. Add Serie I and retain Early/Late.'),
    **dict.fromkeys(['DXXI_SARJA3_EARLY', 'DXXI_SARJA3_LATE'], 'Guide_409m pp13-14: both Sarja 3; Late has self-sealing tank and improved armoured seat. Do not rename to Sarja 4.'),
    **dict.fromkeys(['Il-2_1940_Early', 'Il-2_1940_Late', 'Il-2_1941_Early'], 'Local AAA labels already distinguish Series 1/2/3. Retain, not a new archival certification of Soviet serial batches.'),
    'Il-2_1941_Late': 'Local AAA and Aircraft Guide identify field modification, not Series 4. Preserve description and year.',
    **dict.fromkeys(['Il-2M_Early', 'Il-2M_Late'], 'Local AAA and Aircraft Guide distinguish first/later series; no exact new numbered series established.'),
    'F6F-3': 'AAA and Aircraft Guide pp36-37 explicitly say F6F-3 Late. No numbered production block established; not F6F-5.',
    'P-38L_Late': 'Aircraft Guide pp127-130 retains P-38L Late with different quoted power. It does not identify L-1 versus L-5; retain Late.',
    'P-47D': 'AAA labels P-47D-27-Late, distinct from P-47D-27. Aircraft Guide also has a separate P-47D. No proof of another block; retain D-27 Late as inherited mod label.',
    **dict.fromkeys(['HurricaneMkIearly', 'HurricaneMkILate'], 'Local OS1.1 and community names remain Mk.I. M4T describes fabric-wing/two-blade early fit but supplies no new official Mark for these exact classes.'),
    'TyphoonMkIBLate': 'Local OS1.1 and M4T 2009 explicitly identify Mk.IB Late; no different official Mark established for this class.',
    **dict.fromkeys(['Fw-190D-9_Late', 'Fw-190D-9_Late_DZZMod'], 'Local labels already distinguish 1944/1945 under D-9; retain year and weapon-mod distinction, no invented D-10 subtype.'),
    'Bf-109G-6_Late': 'Aircraft Guide pp318-320 distinguishes G-6 Late from G-6AS. No unique new subtype established; retain Late, not /AS or G-14.',
    **dict.fromkeys(['Il-4_Late', 'La-5F_Early', 'Yak-1B_Early', 'Yak-7B_late', 'Yak-9M_Early', 'Yak-9U_Early', 'IAR80early', 'Bf-109E-1_Late'], 'Local slot and resource audit; historical community inventories searched. No exact numbered series/block established for this mod, so keep the descriptive Early/Late.'),
}
EARLY_LATE['IAR80early'] = UNRESOLVED['IAR80early']
EARLY_LATE['Bf-109E-1_Late'] = UNRESOLVED['Bf-109E-1_Late']

def move_designer_families(data, labels=False):
    """Only relocate affected whole families, preserving every aircraft line."""
    blocks = data.decode('ascii').rstrip('\r\n').split('\r\n\r\n')
    def keys(block):
        return {line.split()[0] for line in block.splitlines()
                if line.strip() and not line.startswith(('#', '[', '!'))}
    def move(selected, anchor):
        picked = [b for b in blocks if keys(b) & selected]
        if not picked:
            return
        blocks[:] = [b for b in blocks if b not in picked]
        matches = [i for i, b in enumerate(blocks) if anchor in keys(b)]
        assert len(matches) == 1, anchor
        i = matches[0] + 1
        blocks[i:i] = picked
    move({'Li-2'}, 'C-47B')
    move({'L2D'}, 'Do-335A-0')
    # S-328 is new in 4.09; in 4.08 the previous family is Kawasaki Ki-100.
    macchi_anchor = 'S-328' if any('S-328' in keys(b) for b in blocks) else 'Ki-100-I-Ko'
    move({'MC-200series1', 'MC-202', 'MC-205_I'}, macchi_anchor)
    if labels:
        blocks = [b.replace('# ALLIES - Lisunov / Li-2', '# ALLIES - Douglas / Li-2')
                  .replace('# AXE - Showa/Nakajima / L2', '# AXE - Douglas / L2D')
                  .replace('# AXE - AerMacchi / MC.', '# AXE - Macchi / C.')
                  .replace('# AXE - Horten-Gotha / Go-229', '# AXE - Horten / Go-229') for b in blocks]
    return ('\r\n\r\n'.join(blocks) + '\r\n').encode('ascii')

def sha(data):
    return hashlib.sha256(data).hexdigest().upper()

def revised(key, label):
    if key in BASE['ACES']:
        return label
    # Preserve the exact source year, including absent years. Parentheses are
    # normalized only when they enclose the existing terminal year.
    date = re.search(r'(?:,\s*|\s*\()(\d{4})(?:\))?(?:\s*\((?:first|later) series\))?$', label)
    body = label[:date.start()].rstrip() if date else label
    suffix = ', ' + date[1] if date else ''
    body = OVERRIDES.get(key, body)
    if key == 'Il-2_1941_Late':
        # This source has its year before "field mod.", not at the end.
        assert label == 'Ilyushin IL-2, 1941 field mod.'
        suffix = ', 1941'
    if key == 'TBM1':
        assert label == 'Grumman TBM1 Avenger, printemps 1942'
        suffix = ', printemps 1942'
    body = re.sub(r'^AerMacchi\s+', 'Macchi ', body)
    body = re.sub(r'\bMC\.(20[025])\b', r'C.\1', body)
    # Keep Alexis's compact embedded designer abbreviations (Yak, MiG, DH).
    body = re.sub(r'^PZL/IAR\s+', 'PZL ', body)
    body = body.replace('KingCobra', 'Kingcobra')
    body = re.sub(r'\bIL-(2|4|10)', r'Il-\1', body)
    body = re.sub(r'\bPe-2 Buck (Series \d+)', r'Pe-2 \1 Buck', body)
    body = body.replace('P-47D-27-Late', 'P-47D-27 Late')
    body = re.sub(r'\b(F-86-[AF])(\d+)', r'\1-\2', body)
    body = re.sub(r'\b(B-25[CGHJ]-\d+|P-51D-\d+)(NA|NT)\b', r'\1-\2', body)
    body = re.sub(r'^FW-(\d+)\s+([A-Z])', r'FW \1\2', body)
    body = re.sub(r'^Me-(\d+)-?', r'Me \1', body)
    body = re.sub(r'\bTa-152C([013])\b', r'Ta-152C-\1', body)
    body = body.replace('G-14AS', 'G-14/AS')
    body = body.replace('G-6_Erla', 'G-6 (Erla)')
    body = body.replace('G-10_Erla2', 'G-10 (Erla2)')
    body = body.replace('G-10_ErlaC3_45', 'G-10 (Erla C3_45)')
    body = body.replace('Kai(Weapon', 'Kai (Weapon')
    body = body.replace('I-15 m22', 'I-15 M-22').replace('I-15 m25', 'I-15 M-25')
    body = re.sub(r'\bIAR 81([ac])\b', lambda m: 'IAR 81' + m[1].upper(), body)
    body = re.sub(r'\b([LH])\.F\.\s*Mk\.', r'\1F Mk.', body)
    body = re.sub(r'\b([FL])\.Mk\.', r'\1 Mk.', body)
    body = re.sub(r'\s+(25)Lbs\b', r' (\1 lbs)', body)
    # Familiar names follow the complete US designation, including its block.
    nickname = None
    if key.startswith(('P-51', 'F51')): nickname = 'Mustang'
    elif key.startswith('P-40') and key != 'P-400': nickname = 'Warhawk'
    elif key.startswith('P-47'): nickname = 'Thunderbolt'
    elif key.startswith('F4U'): nickname = 'Corsair'
    elif key.startswith('SBD-'): nickname = 'Dauntless'
    elif key.startswith('B-17'): nickname = 'Flying Fortress'
    elif key.startswith('B-24'): nickname = 'Liberator'
    elif key in ('P-39D1', 'P-39D2', 'P-400'): nickname = 'Airacobra'
    if nickname and nickname not in body:
        body += ' ' + nickname
    return body + suffix

def observations(rows):
    dump = ROOT / 'WIP/labs/IL 2 Sturmovik 1946 Selector Dump/dump'
    by_key = {r[0]: r for r in rows}
    result = {}
    for key in dict.fromkeys(OBSERVE_KEYS + list(EARLY_LATE)):
        name = 'com.maddox.il2.objects.' + by_key[key][1]
        address = SFS['finger_int'](ord(c) for c in f'sdw{name}cwc2w9e')
        hashed = f"{SFS['finger_string'](0, f'cod/{address}') & 0xFFFFFFFFFFFFFFFF:016X}"
        loose = ROOT / 'Files' / hashed
        source = loose if loose.is_file() else dump / (name.replace('.', '/') + '.class')
        if not source.is_file():
            result[key] = {'class': name, 'status': 'not-found-in-loose-files-or-previous-dump',
                           'limit': 'Not evidence that the aircraft is missing at runtime (SFS not inspected here).'}
            continue
        info = CLASS(source, 'loose' if loose.is_file() else 'previous-4.09m-dump')
        assert info.name == name.replace('.', '/')
        result[key] = {
            'source': source.relative_to(ROOT).as_posix(), 'sourceKind': info.source_kind,
            'sha256': info.sha256, 'class': info.name, 'major': info.major,
            'strings': [s for s in info.strings if re.match(r'(?i)^(FlightModels/|3do/Plane/)', s)],
            'limit': 'Resource references identify the local mod, not proof of historical physics or an exact production block.',
        }
    return result

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--backup-root', type=Path, required=True)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    assert subprocess.check_output(['git', '-C', str(ROOT), 'branch', '--show-current'], text=True).strip() == 'v1.15'
    assert Path(subprocess.check_output(['git', '-C', str(ROOT), 'rev-parse', '--show-toplevel'], text=True).strip()).resolve() == ROOT
    originals = {p: (args.backup_root / p).read_bytes() for p in EXPECTED}
    assert all(sha(originals[p]) == v for p, v in EXPECTED.items()), 'Backup mismatch'
    before, duplicates = BASE['parse_labels'](originals[LABELS])
    assert not duplicates
    after = {k: revised(k, v) for k, v in before.items()}
    assert all(re.findall(r'\b(?:19|20)\d{2}\b', before[k]) ==
               re.findall(r'\b(?:19|20)\d{2}\b', after[k]) for k in before), 'Year lost or changed'
    assert set(OVERRIDES) <= before.keys()
    rows = BASE['parse_air'](originals[AIR_PATHS[0]])
    early_keys = {k for k, label in before.items() if
                  re.search(r'(?:_early|_late|early$|late$)', k, re.I) or
                  re.search(r'\b(?:early|late)\b', label, re.I)}
    assert early_keys <= EARLY_LATE.keys(), ('Unaudited Early/Late', early_keys - EARLY_LATE.keys())
    assert set(UNRESOLVED) <= {r[0] for r in rows}
    assert all(after[k] == before[k] for k in BASE['ACES'])
    # Change display values in place. Blank lines and family order remain.
    lines = []
    for line in originals[LABELS].decode('ascii').splitlines():
        if line and not line.startswith(('#', '!')):
            key, old = line.split(None, 1)
            line = line[:len(line) - len(old)] + after[key]
        lines.append(line)
    payload = move_designer_families(('\r\n'.join(lines) + '\r\n').encode('ascii'), labels=True)
    parsed, duplicates = BASE['parse_labels'](payload)
    assert not duplicates and parsed == after
    products = {p: move_designer_families(originals[p]) for p in AIR_PATHS}
    products[LABELS] = payload
    switcher = originals[BASE['SWITCHER']]
    for p in AIR_PATHS[1:]:
        assert switcher.count(EXPECTED[p].encode()) == 1
        switcher = switcher.replace(EXPECTED[p].encode(), sha(products[p]).encode())
    products[BASE['SWITCHER']] = switcher
    for p in AIR_PATHS:
        old_rows, new_rows = BASE['parse_air'](originals[p]), BASE['parse_air'](products[p])
        assert Counter(map(tuple, old_rows)) == Counter(map(tuple, new_rows))
        moved = {r[0] for r in old_rows if r[0] in ('Li-2', 'L2D') or r[0].startswith('MC-20')}
        assert [r for r in old_rows if r[0] not in moved] == [r for r in new_rows if r[0] not in moved]
        assert [r for r in old_rows if r[0] in BASE['ACES']] == [r for r in new_rows if r[0] in BASE['ACES']]
    assert products[AIR_PATHS[0]] == products[AIR_PATHS[2]]
    assert list(parsed)[:len(rows)] == [r[0] for r in BASE['parse_air'](products[AIR_PATHS[0]])]
    assert all((ROOT / p).read_bytes() in (originals[p], v) for p, v in products.items()), 'Concurrent presentation edit'
    makers = {m for m, _ in BASE['MAKER_PREFIXES']} | {'Macchi', 'Curtiss-Wright', 'Horten'}
    makers |= {'N.A', 'V.S', 'Me', 'FW', 'RWD', 'Yak', 'MiG', 'DH'}
    review = []
    for row in rows:
        key = row[0]
        value = after[key]
        if key in BASE['ACES']:
            maker, designation = None, value
        else:
            matches = [m for m in makers if re.match(re.escape(m) + r'(?:\s|[.-])', value)]
            matches.sort(key=len, reverse=True)
            assert matches and (len(matches) == 1 or len(matches[0]) > len(matches[1])), (key, value, matches)
            maker = matches[0]
            designation = value[len(maker):].lstrip(' .-')
            assert designation and not re.search(r'\b(?:Mustang P-51|Buffalo F2A|Buck Series)\b', designation), key
        review.append({'key': key, 'originalDesignerLabel': maker, 'modelVariantAndName': designation,
                       'before': before[key], 'after': value,
                       'review': 'unresolved-mod-detail' if key in UNRESOLVED else 'local-identity-and-presentation-reviewed',
                       'note': UNRESOLVED.get(key)})
    report = {
        'status': 'APPLIED' if args.apply else 'PREVIEW', 'date': '2026-09-07',
        'backupRoot': str(args.backup_root), 'policy': 'Original designer, designation/model and variant, then optional US nickname; British model names retain their Mark. No licensee suffix; keep compact designer abbreviations and families. Aces untouched.',
        'beforeSha256': EXPECTED[LABELS], 'afterSha256': sha(payload),
        'counts': {p: len(BASE['parse_air'](originals[p])) for p in AIR_PATHS},
        'labelsReviewed': len(review), 'changedLabels': sum(before[k] != after[k] for k in before),
        'files': {p: {'sha256': sha(v), 'bytes': len(v)} for p, v in products.items()},
        'technicalTokensUnchanged': True, 'acesUnchanged': True,
        'onlyFamilyMoves': ['Li-2 after C-47 family under Douglas', 'L2D under Douglas in Axis', 'Macchi after Letov before Messerschmitt'],
        'earlyLateReview': EARLY_LATE,
        'unresolved': UNRESOLVED, 'resourceObservations': observations(rows), 'entries': review,
        'runtimeValidation': 'pending', 'historicalCertificationOfEveryMod': False,
        'sourcesDocument': 'docs/REVISION_NOMS_AVIONS_V1.15.md',
    }
    build = ROOT / 'build/aircraft-name-review'
    build.mkdir(parents=True, exist_ok=True)
    (build / 'plane_ru.properties').write_bytes(payload)
    (build / 'review.json').write_text(json.dumps(report, indent=2, ensure_ascii=True) + '\n', encoding='ascii')
    if args.apply:
        for p, data in products.items():
            (ROOT / p).write_bytes(data)
        manifest_path = ROOT / 'manifests/aircraft/presentation-v1.15.json'
        manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
        manifest['files'] = report['files']
        manifest['nameReviewReport'] = 'manifests/aircraft/name-review-v1.15.json'
        manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=True) + '\n', encoding='ascii')
        (ROOT / manifest['nameReviewReport']).write_text(json.dumps(report, indent=2, ensure_ascii=True) + '\n', encoding='ascii')
    print(f"PASS: {len(review)} entries reviewed, {report['changedLabels']} names changed, counts 535/516/535, technical tokens/aces unchanged; {len(EARLY_LATE)} Early/Late cases checked; {len(UNRESOLVED)} mod details not historically certified; applied={args.apply}")
    for row in review:
        if row['before'] != row['after']:
            print(row['key'] + ': ' + row['before'] + ' -> ' + row['after'])

if __name__ == '__main__':
    main()
