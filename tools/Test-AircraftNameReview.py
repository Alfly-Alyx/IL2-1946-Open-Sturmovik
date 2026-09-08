#!/usr/bin/env python3
"""Read-only regression checks for the v1.15 name review; never launches IL-2."""
from collections import Counter
import json
from pathlib import Path
import re
import runpy
import unittest

ROOT = Path(__file__).resolve().parent.parent
M = runpy.run_path(str(ROOT / 'tools/Review-AircraftNames.py'))


class AircraftNames(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.report = json.loads((ROOT / 'manifests/aircraft/name-review-v1.15.json').read_text())
        cls.labels, duplicates = M['BASE']['parse_labels']((ROOT / M['LABELS']).read_bytes())
        assert not duplicates
        cls.backup = Path(cls.report['backupRoot'])

    def test_complete_review(self):
        self.assertEqual(len(self.report['entries']), 535)
        self.assertEqual(self.report['changedLabels'], 188)
        self.assertEqual(len(self.report['earlyLateReview']), 27)

    def test_original_designers(self):
        for key, maker in {'FM-2': 'Grumman', 'TBM1': 'Grumman', 'TBM-3': 'Grumman',
                           'AvengerMkIII': 'Grumman', 'CorsairMkIV': 'Vought',
                           'P_24e': 'PZL', 'L2D': 'Douglas', 'Li-2': 'Douglas',
                           'Go-229A-1': 'Horten', 'MC-202': 'Macchi'}.items():
            self.assertTrue(self.labels[key].startswith(maker + ' '), key)

    def test_bell_is_not_warhawk(self):
        self.assertEqual(self.labels['P-400'], 'Bell P-400 Airacobra, 1941')
        self.assertIn('Warhawk', self.labels['P-40B'])

    def test_raf_names_not_us_conversions(self):
        for key in ('MustangIII', 'MustangIV', 'TomahawkMkIIa', 'TomahawkMkIIb', 'CorsairMkIV'):
            row = next(r for r in self.report['entries'] if r['key'] == key)
            self.assertEqual(row['before'], row['after'])
        self.assertIn('P-51D-20-NA Mustang', self.labels['P-51D-20NA'])

    def test_known_series_keep_configuration(self):
        for key in ('G-55', 'G-55-Late'):
            self.assertIn('Serie I', self.labels[key])
        self.assertIn('Early', self.labels['G-55'])
        self.assertIn('Late', self.labels['G-55-Late'])
        for key in ('DXXI_SARJA3_EARLY', 'DXXI_SARJA3_LATE'):
            self.assertIn('Sarja 3', self.labels[key])
        self.assertIn('Serie IV', self.labels['AviaB534'])

    def test_no_guessed_blocks(self):
        for key in ('P-51D', 'P-51D2', 'F84G1_ThunderJet', 'F84G3_ThunderJet'):
            self.assertIn('(mod ', self.labels[key])
        self.assertIn('Late', self.labels['P-38L_Late'])
        self.assertIn('D-27 Late', self.labels['P-47D'])
        self.assertIn('G-6 Late', self.labels['Bf-109G-6_Late'])
        for key in ('IAR80early', 'Bf-109E-1_Late'):
            self.assertIn(key, self.report['unresolved'])

    def test_dates_preserved(self):
        for row in self.report['entries']:
            self.assertEqual(re.findall(r'\b(?:19|20)\d{2}\b', row['before']),
                             re.findall(r'\b(?:19|20)\d{2}\b', row['after']), row['key'])
        self.assertTrue(self.labels['Il-2_1941_Late'].endswith(', 1941'))
        self.assertTrue(self.labels['TBM1'].endswith(', printemps 1942'))

    def test_technical_identity_counts_and_aces(self):
        for path, count in zip(M['AIR_PATHS'], (535, 516, 535)):
            legacy_path = path.replace('_Game Switcher', '_Game Switchers', 1)
            old = M['BASE']['parse_air']((self.backup / legacy_path).read_bytes())
            new = M['BASE']['parse_air']((ROOT / path).read_bytes())
            self.assertEqual(len(new), count)
            self.assertEqual(Counter(map(tuple, old)), Counter(map(tuple, new)))
            aces = [r for r in new if r[0] in M['BASE']['ACES']]
            self.assertEqual(len(aces), 14 if count == 516 else 15)
            self.assertEqual(aces, new[-len(aces):])
            self.assertEqual(aces, [r for r in old if r[0] in M['BASE']['ACES']])
            old_labels = M['BASE']['parse_labels']((self.backup / M['LABELS']).read_bytes())[0]
            for row in aces:
                self.assertEqual(self.labels[row[0]], old_labels[row[0]])

    def test_moved_and_preserved_families(self):
        for path in M['AIR_PATHS']:
            rows = M['BASE']['parse_air']((ROOT / path).read_bytes())
            keys = [r[0] for r in rows]
            for first, second in [('C-47B', 'Li-2'), ('Li-2', 'A-20C'),
                                  ('Do-335A-0', 'L2D'), ('L2D', 'CR-32quater'),
                                  ('Ki-100-I-Ko', 'MC-200series1'), ('MC-205_IIIV', 'Bf-109B-2'),
                                  ('HurricaneMkIearly', 'HurricaneMkI'), ('SpitfireMkIXc', 'SpitfireMkVIII'),
                                  ('Bf-109G-14', 'Bf-109G-10')]:
                self.assertLess(keys.index(first), keys.index(second))

    def test_hashes_and_switcher(self):
        manifest = json.loads((ROOT / 'manifests/aircraft/presentation-v1.15.json').read_text())
        switcher = (ROOT / M['BASE']['SWITCHER']).read_bytes()
        for path, info in self.report['files'].items():
            payload = (ROOT / path).read_bytes()
            if path == M['BASE']['SWITCHER']:
                # The naming report predates the beta-registry/state fixes.
                current = json.loads((ROOT / 'manifests/switcher-v1.15.json').read_text())
                self.assertEqual(current['entryPointSha256'], M['sha'](payload))
                self.assertEqual(manifest['files'][path]['sha256'], M['sha'](payload))
                continue
            self.assertEqual(info['sha256'], M['sha'](payload))
            self.assertEqual(info, manifest['files'][path])
        for path in M['AIR_PATHS'][1:]:
            self.assertIn(self.report['files'][path]['sha256'].encode(), switcher)

    def test_beta_registry_preserves_current_presentation(self):
        parse = M['BASE']['parse_air']
        historical = parse((ROOT / M['AIR_PATHS'][1]).read_bytes())
        final = parse((ROOT / M['AIR_PATHS'][2]).read_bytes())
        beta = parse((ROOT / '_Game Switcher/409b air.ini/Air.ini/air.ini').read_bytes())
        historical_keys = {row[0] for row in historical}
        self.assertEqual(len(beta), 516)
        self.assertEqual(beta, [row for row in final if row[0] in historical_keys])
        self.assertEqual({row[0] for row in beta}, historical_keys)
        self.assertNotIn('CW-21', historical_keys)
        manifest = json.loads((ROOT / 'manifests/switcher-v1.15.json').read_text())
        info = manifest['airRegistries']['4.09b']
        self.assertEqual(info['sha256'], M['sha']((ROOT / info['path']).read_bytes()))

    def test_encoding_and_label_order(self):
        payload = (ROOT / M['LABELS']).read_bytes()
        payload.decode('ascii')
        self.assertNotIn(b'\n', payload.replace(b'\r\n', b''))
        active = M['BASE']['parse_air']((ROOT / M['AIR_PATHS'][0]).read_bytes())
        self.assertEqual(list(self.labels)[:535], [r[0] for r in active])


if __name__ == '__main__':
    unittest.main(verbosity=2)
