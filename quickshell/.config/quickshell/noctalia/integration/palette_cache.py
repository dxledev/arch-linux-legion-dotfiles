"""Cache orchestration for the Bash static-palette entrypoint."""
import argparse
import fcntl
import hashlib
import json
import math
import os
from pathlib import Path
import re
import tempfile
import sys
import tomllib

from palette_colors import KEYS, ROLES, complete, native_candidates, normalize, validate, validate_terminal

MAPPING = dict(zip(ROLES, ('primary', 'background', 'secondary', 'background', 'warning',
                          'background', 'danger', 'background', 'background', 'foreground',
                          'backgroundAlt', 'foregroundInactive', 'border', 'background',
                          'secondary', 'background')))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def serialized(data):
    return (json.dumps(data, indent=2, ensure_ascii=True) + '\n').encode()


def source_colors(theme):
    text = (theme / 'Colors.qml').read_text()
    colors = {}
    for name in set(MAPPING.values()) | {'muted', 'success'}:
        match = re.search(r'property\s+color\s+' + name + r'\s*:\s*([^\n]+)', text)
        if not match:
            raise ValueError(f'Missing Colors.qml role {name}')
        value = match[1]
        hex_match = re.search(r'#(?:[0-9a-fA-F]{8}|[0-9a-fA-F]{6})(?![0-9a-fA-F])', value)
        rgba_match = re.search(r'Qt\.rgba\(\s*(\d+)\s*/\s*255\s*,\s*(\d+)\s*/\s*255\s*,\s*(\d+)\s*/\s*255', value)
        if hex_match:
            colors[name] = normalize(hex_match[0][-6:])
        elif rgba_match and all(0 <= int(v) <= 255 for v in rgba_match.groups()):
            colors[name] = '#' + ''.join(f'{int(v):02x}' for v in rgba_match.groups())
        else:
            raise ValueError(f'Unsupported Colors.qml role {name}')
    return colors


def waybar_background(theme):
    definitions = dict(re.findall(r'@define-color\s+([\w-]+)\s+([^;]+);', (theme / 'waybar.css').read_text()))
    def resolve(value, visited):
        reference = re.search(r'@([\w-]+)', value)
        if reference:
            name = reference[1]
            if name in visited or name not in definitions:
                raise ValueError('Invalid Waybar background reference')
            return resolve(definitions[name], visited | {name})
        hexadecimal = re.search(r'#[0-9a-fA-F]{6}(?![0-9a-fA-F])', value)
        if hexadecimal:
            return normalize(hexadecimal[0])
        rgba = re.fullmatch(r'rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*(?:0?\.\d+|[01]))?\s*\)', value.strip())
        if rgba and all(0 <= int(channel) <= 255 for channel in rgba.groups()):
            return '#' + ''.join(f'{int(channel):02x}' for channel in rgba.groups())
        raise ValueError('Unsupported Waybar background')
    return resolve(definitions['background'], {'background'})


def mapped_terminal(theme, colors):
    terminal_source = tomllib.loads((theme / 'alacritty.toml').read_text())['colors']
    names = ('black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white')
    terminal = {section: {name: normalize(terminal_source[section][name]) for name in names}
                for section in ('normal', 'bright')}
    terminal.update(dict(foreground=colors['foreground'], background=colors['background'],
                         cursor=colors['foreground'], cursorText=colors['background'],
                         selectionFg=colors['foreground'], selectionBg=colors['backgroundAlt']))
    return terminal


def source_palette(theme):
    colors = source_colors(theme)
    original = {role: colors[MAPPING[role]] for role in ROLES}
    original['surface'] = waybar_background(theme)
    return original, mapped_terminal(theme, colors), sorted(set(colors.values()) | {original['surface']})


def preserved_terminal(theme, fallback):
    for name in ('noctalia.json', 'noctalia.meta.json'):
        try:
            record = json.loads((theme / name).read_bytes())
            terminal = record['terminal'] if name.endswith('meta.json') else record['dark']['terminal']
            validate_terminal(terminal)
            return terminal
        except (OSError, ValueError, KeyError, TypeError):
            continue
    validate_terminal(fallback)
    return fallback


def fingerprints(theme, binary, settings):
    here = Path(__file__).parent
    return {'inputs': {name: digest(theme / name) for name in ('Colors.qml', 'alacritty.toml', 'waybar.css')},
            'logic': {name: digest(here / name) for name in ('generate-palettes', 'palette_cache.py', 'palette_colors.py')},
            'settings': settings, 'noctalia': {'path': str(binary), 'sha256': digest(binary)}}


def cache_valid(output, metadata, fingerprint, original_terminal, settings):
    try:
        record = json.loads(metadata.read_bytes())
        if record['fingerprints'] != fingerprint or record['output_sha256'] != digest(output):
            return False
        payload = json.loads(output.read_bytes())
        validate(payload, **settings)
        return payload['dark']['terminal'] == original_terminal
    except (OSError, ValueError, KeyError, TypeError):
        return False


def atomic_write(path, content):
    descriptor, temporary = tempfile.mkstemp(prefix=f'.{path.name}.', dir=path.parent)
    try:
        with os.fdopen(descriptor, 'wb') as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, 0o644)
        os.replace(temporary, path)
        directory = os.open(path.parent, os.O_DIRECTORY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def process_theme(theme, binary, settings, write, force):
    output, metadata = theme / 'noctalia.json', theme / 'noctalia.meta.json'
    original, terminal, seeds = source_palette(theme)
    terminal = preserved_terminal(theme, terminal)
    fingerprint = fingerprints(theme, binary, settings)
    if not force and cache_valid(output, metadata, fingerprint, terminal, settings):
        print(f'{theme.name}: cache hit')
        return
    with tempfile.TemporaryDirectory(prefix='noctalia-palettes-') as temporary:
        generated = native_candidates(binary, seeds, Path(temporary))
        selected = complete(original, generated, **settings)
    palette = {KEYS[role]: selected[role] for role in ROLES}
    palette['terminal'] = terminal
    payload = {'dark': palette, 'light': palette}
    data = serialized(payload)
    validate(json.loads(data), **settings)
    if fingerprints(theme, binary, settings) != fingerprint:
        raise ValueError('Inputs changed during generation; retry')
    changes = [f'{role} {original[role]} → {selected[role]}' for role in ROLES if original[role] != selected[role]]
    if write:
        atomic_write(output, data)
        atomic_write(metadata, serialized({'fingerprints': fingerprint, 'output_sha256': hashlib.sha256(data).hexdigest(), 'terminal': terminal}))
    print(f'{theme.name}: {"saved" if write else "would regenerate"}; {len(changes)} replacements')
    for change in changes:
        print(f'  {change}')


def options():
    parser = argparse.ArgumentParser(description='Generate validated cached Noctalia static palettes (default: dry-run).')
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--write', action='store_true')
    mode.add_argument('--dry-run', action='store_true')
    parser.add_argument('--theme', metavar='NAME')
    parser.add_argument('--force', action='store_true')
    parser.add_argument('--min-distance', type=float, default=os.environ.get('NOCTALIA_PALETTE_MIN_DISTANCE', '.04'))
    parser.add_argument('--min-contrast', type=float, default=os.environ.get('NOCTALIA_PALETTE_MIN_CONTRAST', '4.5'))
    parser.add_argument('--variant-distance', type=float, default=.08, help='Maximum OKLab distance of surface variant from surface (default: 0.08)')
    parser.add_argument('--variant-chroma', type=float, default=.02, help='Maximum OKLab chromatic shift from surface (default: 0.02)')
    args = parser.parse_args()
    if not math.isfinite(args.variant_distance) or not args.min_distance <= args.variant_distance <= 1:
        parser.error('--variant-distance must be between --min-distance and 1')
    if not math.isfinite(args.variant_chroma) or not 0 <= args.variant_chroma <= 1:
        parser.error('--variant-chroma must be between 0 and 1')
    if not math.isfinite(args.min_distance) or not .04 <= args.min_distance <= 1:
        parser.error('--min-distance must be between 0.04 and 1')
    if not math.isfinite(args.min_contrast) or not 4.5 <= args.min_contrast <= 21:
        parser.error('--min-contrast must be between 4.5 and 21')
    return parser, args


def theme_paths(parser, args):
    config = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config')))
    themes = Path(os.environ.get('THEMES_DIR', str(config / 'themes'))).resolve()
    binary = Path(os.environ.get('NOCTALIA_BIN', str(config / 'noctalia/.runtime/bin/noctalia'))).resolve()
    if not themes.is_dir() or not binary.is_file() or not os.access(binary, os.X_OK):
        parser.error('Themes directory or executable Noctalia binary missing')
    if args.theme and not re.fullmatch(r'[a-z0-9][a-z0-9._-]*', args.theme):
        parser.error('Invalid theme name')
    available = [theme for theme in sorted(themes.iterdir()) if theme.is_dir() and theme.name != 'current' and not theme.name.startswith('.')]
    if args.theme:
        available = [theme for theme in available if theme.name == args.theme]
        if not available:
            parser.error(f'Unknown static theme: {args.theme}')
    return available, binary


def main():
    parser, args = options()
    available, binary = theme_paths(parser, args)
    settings = {'separation': args.min_distance, 'minimum_contrast': args.min_contrast,
                'variant_distance': args.variant_distance, 'variant_chroma': args.variant_chroma}
    failed = False
    for theme in available:
        try:
            # Lock files live beside caches; dry-run never creates or updates them.
            if args.write:
                with (theme / '.noctalia.lock').open('a') as lock:
                    fcntl.flock(lock, fcntl.LOCK_EX)
                    process_theme(theme, binary, settings, True, args.force)
            else:
                process_theme(theme, binary, settings, False, args.force)
        except Exception as error:
            print(f'{theme.name}: failed: {error}; previous saved palette retained', file=sys.stderr)
            failed = True
    return int(failed)


if __name__ == '__main__':
    raise SystemExit(main())
