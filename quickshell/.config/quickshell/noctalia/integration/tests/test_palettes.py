import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

INTEGRATION = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(INTEGRATION))
from palette_cache import source_palette, source_colors, waybar_background
from palette_colors import KEYS, ROLES, complete, constraints, contrast, distance, metrics, validate


class ColorTests(unittest.TestCase):
    def test_qt_argb_normalizes_to_rgb(self):
        with tempfile.TemporaryDirectory() as temporary:
            theme = Path(temporary)
            source = (Path.home() / '.config/themes/akaito/Colors.qml').read_text()
            source = source.replace('#f3e4cb', '#80f3e4cb')
            (theme / 'Colors.qml').write_text(source)
            self.assertEqual(source_colors(theme)['background'], '#f3e4cb')

    def test_waybar_background_forms_and_reserved_surface(self):
        with tempfile.TemporaryDirectory() as temporary:
            theme = Path(temporary)
            for value in ('#123456', 'rgba(18, 52, 86, 0.88)', 'alpha(#123456, 0.8)', 'alpha(@background-alt, 0.8)'):
                (theme / 'waybar.css').write_text(f'@define-color background {value};\n@define-color background-alt #123456;')
                self.assertEqual(waybar_background(theme), '#123456')
        original, _, _ = source_palette(Path.home() / '.config/themes/manga')
        original['primary'] = original['surface']
        result = complete(original, {'#000000', '#ffffff'})
        self.assertEqual(result['surface'], original['surface'])
        self.assertGreaterEqual(distance(result['primary'], result['surface']), .04)

    def test_surface_variant_limits_are_configurable(self):
        selected = {'surface': '#121212'}
        color = '#252525'
        self.assertTrue(constraints('surface_variant', color, selected, False, .04, 4.5, .2, .02))
        self.assertFalse(constraints('surface_variant', color, selected, False, .04, 4.5, .04, .02))

    def test_reference_metrics(self):
        self.assertAlmostEqual(contrast('#000000', '#ffffff'), 21)
        self.assertAlmostEqual(metrics('#ffffff')[0][0], 1, places=6)
        self.assertAlmostEqual(distance('#000000', '#ffffff'), 1, places=6)

    def test_priority_and_readability(self):
        themes = Path(os.environ.get('THEMES_DIR', str(Path.home() / '.config/themes')))
        for name in ('akaito', 'manga', 'matte-black'):
            with self.subTest(theme=name):
                original, terminal, _ = source_palette(themes / name)
                result = complete(original, {'#000000', '#ffffff'})
                self.assertLessEqual(distance(result['surface_variant'], result['surface']), .08)
                _, a, b = metrics(result['surface_variant'])[0]
                _, sa, sb = metrics(result['surface'])[0]
                self.assertLessEqual(((a-sa)**2 + (b-sb)**2)**.5, .02)
                earlier = {'surface': original['surface']}
                light = metrics(original['surface'])[0][0] >= .6
                for role in ROLES:
                    if role == 'surface':
                        self.assertEqual(original[role], result[role])
                        continue
                    if constraints(role, original[role], earlier, light, .04, 4.5):
                        self.assertEqual(original[role], result[role], role)
                    earlier[role] = result[role]
                self.assertEqual(original['primary'], result['primary'])
                self.assertEqual(result, complete(result, {'#000000', '#ffffff'}))
                palette = {KEYS[role]: result[role] for role in ROLES}
                palette['terminal'] = terminal
                validate({'dark': palette, 'light': palette})


class CacheTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.integration = self.root / 'integration'
        self.integration.mkdir()
        for name in ('generate-palettes', 'palette_cache.py', 'palette_colors.py'):
            shutil.copy2(INTEGRATION / name, self.integration / name)
        self.theme = self.root / 'themes' / 'akaito'
        self.theme.mkdir(parents=True)
        source = Path.home() / '.config/themes/akaito'
        for name in ('Colors.qml', 'alacritty.toml', 'waybar.css', 'noctalia.json'):
            shutil.copy2(source / name, self.theme / name)
        self.count = self.root / 'calls'
        self.binary = self.root / 'native'
        self.binary.write_text('#!/usr/bin/python3\nimport json, os\nfrom pathlib import Path\np=Path(os.environ["TEST_CALLS"])\np.write_text(p.read_text()+"call\\n" if p.exists() else "call\\n")\nprint(json.dumps({mode:{"primary":"#ffffff", "surface":"#000000"} for mode in ("dark", "light")}))\n')
        self.binary.chmod(0o755)
        self.env = dict(os.environ, THEMES_DIR=str(self.root / 'themes'), NOCTALIA_BIN=str(self.binary),
                        TEST_CALLS=str(self.count), PYTHONDONTWRITEBYTECODE='1')

    def tearDown(self):
        self.temporary.cleanup()

    def run_generator(self, *args, success=True):
        result = subprocess.run(['/bin/bash', str(self.integration / 'generate-palettes'), *args],
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode == 0, success, result.stderr)
        return result.stdout

    def snapshot(self):
        return {p.name: (hashlib.sha256(p.read_bytes()).hexdigest(), p.stat().st_mtime_ns)
                for p in self.theme.iterdir()}

    def test_dry_run_determinism_cache_and_terminal(self):
        before = self.snapshot()
        self.run_generator('--force')
        self.assertEqual(before, self.snapshot())
        old_terminal = json.loads((self.theme / 'noctalia.json').read_text())['dark']['terminal']
        self.run_generator('--write')
        saved = self.snapshot()
        calls = self.count.read_bytes()
        self.assertIn('cache hit', self.run_generator('--write'))
        self.assertEqual(calls, self.count.read_bytes())
        self.assertEqual(saved, self.snapshot())
        self.run_generator('--write', '--force')
        self.assertEqual(saved['noctalia.json'][0], self.snapshot()['noctalia.json'][0])
        self.assertEqual(saved['noctalia.meta.json'][0], self.snapshot()['noctalia.meta.json'][0])
        self.assertEqual(old_terminal, json.loads((self.theme / 'noctalia.json').read_text())['dark']['terminal'])

    def test_inputs_logic_settings_executable_and_corruption(self):
        self.run_generator('--write')
        for path in (self.theme / 'Colors.qml', self.theme / 'alacritty.toml', self.theme / 'waybar.css',
                     self.integration / 'palette_colors.py', self.binary):
            with self.subTest(path=path.name):
                comment = '\n/* fingerprint change */\n' if path.suffix == '.css' else ('\n// fingerprint change\n' if path.suffix == '.qml' else '\n# fingerprint change\n')
                with path.open('a') as stream:
                    stream.write(comment)
                self.assertIn('saved', self.run_generator('--write'))
        self.assertIn('saved', self.run_generator('--write', '--min-distance', '.041'))
        self.run_generator('--write')
        output = self.theme / 'noctalia.json'
        output.write_text('{}')
        self.assertIn('saved', self.run_generator('--write'))
        (self.theme / 'noctalia.meta.json').write_text('broken')
        self.assertIn('saved', self.run_generator('--write'))
        output.unlink()
        self.assertIn('saved', self.run_generator('--write'))

    def test_failures_preserve_output(self):
        self.run_generator('--write')
        before = self.snapshot()
        self.run_generator('--write', '--force', '--min-distance', '1', success=False)
        self.assertEqual(before, self.snapshot())
        self.binary.write_text('#!/bin/bash\nexit 1\n')
        self.run_generator('--write', success=False)
        self.assertEqual(before, self.snapshot())

    def test_shell_only_preserves_existing_terminal_and_recovers_it(self):
        output = self.theme / 'noctalia.json'
        payload = json.loads(output.read_text())
        for mode in ('dark', 'light'):
            payload[mode]['terminal']['background'] = '#123456'
            payload[mode]['terminal']['cursorText'] = '#123456'
        terminal = payload['dark']['terminal']
        output.write_text(json.dumps(payload))
        self.run_generator('--write')
        self.assertEqual(terminal, json.loads(output.read_text())['dark']['terminal'])
        source = self.theme / 'alacritty.toml'
        before_source = source.read_bytes()
        with source.open('a') as stream:
            stream.write('\n# updated application source\n')
        expected_source = source.read_bytes()
        self.run_generator('--write')
        self.assertEqual(expected_source, source.read_bytes())
        self.assertNotEqual(before_source, expected_source)
        self.assertEqual(terminal, json.loads(output.read_text())['dark']['terminal'])
        output.write_text('corrupt')
        self.run_generator('--write')
        self.assertEqual(terminal, json.loads(output.read_text())['dark']['terminal'])
        output.unlink()
        self.run_generator('--write')
        self.assertEqual(terminal, json.loads(output.read_text())['dark']['terminal'])

    def test_competing_writers(self):
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
            outputs = list(pool.map(lambda _: self.run_generator('--write'), range(2)))
        self.assertEqual(sum('saved' in output for output in outputs), 1)
        self.assertEqual(sum('cache hit' in output for output in outputs), 1)
        payload = json.loads((self.theme / 'noctalia.json').read_text())
        validate(payload)


if __name__ == '__main__':
    unittest.main()
