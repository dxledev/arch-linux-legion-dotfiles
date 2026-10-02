"""Deterministic final-hex color selection and static palette validation."""
import functools
import itertools
import math
import re
import struct
import subprocess
import zlib

ROLES = ('primary', 'on_primary', 'secondary', 'on_secondary', 'tertiary',
         'on_tertiary', 'error', 'on_error', 'surface', 'on_surface',
         'surface_variant', 'on_surface_variant', 'outline', 'shadow', 'hover', 'on_hover')
KEYS = {role: 'm' + ''.join(word.title() for word in role.split('_')) for role in ROLES}
HEX = re.compile(r'^#[0-9a-f]{6}$')


def normalize(color):
    color = '#' + color.lstrip('#').lower()
    if not HEX.fullmatch(color):
        raise ValueError(f'Invalid color: {color}')
    return color


@functools.lru_cache(maxsize=131072)
def metrics(color):
    rgb = [int(color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    r, g, b = [v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in rgb]
    l = (.4122214708*r + .5363325363*g + .0514459929*b) ** (1/3)
    m = (.2119034982*r + .6806995451*g + .1073969566*b) ** (1/3)
    s = (.0883024619*r + .2817188376*g + .6299787005*b) ** (1/3)
    return ((.2104542553*l + .793617785*m - .0040720468*s,
             1.9779984951*l - 2.428592205*m + .4505937099*s,
             .0259040371*l + .7827717662*m - .808675766*s),
            .2126*r + .7152*g + .0722*b)


def distance(first, second):
    return math.dist(metrics(first)[0], metrics(second)[0])


def contrast(first, second):
    a, b = sorted((metrics(first)[1], metrics(second)[1]))
    return (b + .05) / (a + .05)


def from_lab(lightness, chroma, hue):
    a, b = chroma * math.cos(hue), chroma * math.sin(hue)
    l = (lightness + .3963377774*a + .2158037573*b) ** 3
    m = (lightness - .1055613458*a - .0638541728*b) ** 3
    s = (lightness - .0894841775*a - 1.291485548*b) ** 3
    linear = (4.0767416621*l - 3.3077115913*m + .2309699292*s,
              -1.2684380046*l + 2.6097574011*m - .3413193965*s,
              -.0041960863*l - .7034186147*m + 1.707614701*s)
    if any(v < -1e-7 or v > 1.0000001 for v in linear):
        return None
    rgb = [round(255 * (12.92*v if v <= .0031308 else 1.055*max(v, 0)**(1/2.4) - .055)) for v in linear]
    return '#' + ''.join(f'{max(0, min(255, v)):02x}' for v in rgb)


@functools.lru_cache(maxsize=1)
def adjustment_grid():
    return frozenset(color for l, c, h in itertools.product(range(101), range(14), range(24))
                     if (color := from_lab(l / 100, c / 50, h * math.pi / 12)))


def adjustments(original):
    l, a, b = metrics(original)[0]
    chroma, hue = math.hypot(a, b), math.atan2(b, a)
    result = set(adjustment_grid())
    for dl, dc, dh in itertools.product(range(-8, 9), (-.04, -.02, 0, .02, .04), (-30, -15, 0, 15, 30)):
        color = from_lab(max(0, min(1, l + dl / 100)), max(0, chroma + dc), hue + math.radians(dh))
        if color:
            result.add(color)
    return result


def swatch(path, colors):
    colors = [bytes.fromhex(c[1:]) for c in colors]
    rows = [b'\0' + b''.join(colors[(x // 16 + y // 16) % len(colors)] for x in range(128)) for y in range(128)]
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>2I5B', 128, 128, 8, 2, 0, 0, 0))
                     + chunk(b'IDAT', zlib.compress(b''.join(rows))) + chunk(b'IEND', b''))


def native_candidates(binary, seeds, temporary):
    import json
    candidates = set()
    # A combined swatch and each unique source color retain minority accents.
    for index, colors in enumerate([seeds] + [[seed] for seed in sorted(set(seeds))]):
        path = temporary / f'swatch-{index}.png'
        swatch(path, colors)
        process = subprocess.run([str(binary), 'theme', str(path), '--scheme', 'm3-content', '--both'],
                                 capture_output=True, text=True, timeout=60, check=True)
        payload = json.loads(process.stdout)
        for mode in ('dark', 'light'):
            candidates.update(normalize(value) for value in payload[mode].values() if isinstance(value, str) and HEX.fullmatch(value.lower()))
    if not candidates:
        raise ValueError('Native generator produced no colors')
    return candidates


def constraints(role, color, selected, light, separation, minimum_contrast, variant_distance=.08, variant_chroma=.02):
    if any(distance(color, earlier) < separation for earlier in selected.values()):
        return False
    if role.startswith('on_') and contrast(color, selected[role[3:]]) < minimum_contrast:
        return False
    if role in ('surface', 'surface_variant'):
        l = metrics(color)[0][0]
        if not (.75 <= l <= 1 if light else .08 <= l <= .45):
            return False
    if role == 'surface_variant':
        surface = selected['surface']
        _, a, b = metrics(color)[0]
        _, sa, sb = metrics(surface)[0]
        if distance(color, surface) > variant_distance or math.hypot(a - sa, b - sb) > variant_chroma:
            return False
    if role == 'shadow' and metrics(color)[1] >= metrics(selected['surface'])[1]:
        return False
    return True


def complete(original, generated, separation=.04, minimum_contrast=4.5, variant_distance=.08, variant_chroma=.02):
    # Reserve the reference background before any colliding role is selected.
    selected = {'surface': original['surface']}
    light = metrics(original['surface'])[0][0] >= .6
    for role in ROLES:
        if role == 'surface':
            continue
        color = original[role]
        if not constraints(role, color, selected, light, separation, minimum_contrast, variant_distance, variant_chroma):
            valid = lambda candidate: constraints(role, candidate, selected, light, separation, minimum_contrast, variant_distance, variant_chroma)
            native = [candidate for candidate in generated if valid(candidate)]
            # Compare final hex candidates, including nearby adjustments, to minimize change.
            candidates = set(native) | adjustments(color)
            ranked = sorted(candidates, key=lambda candidate: (distance(color, candidate), candidate not in generated, candidate))
            color = next((candidate for candidate in ranked if valid(candidate)), None)
            if color is None:
                raise ValueError(f'No valid replacement for {role}; earlier roles: {selected}')
        selected[role] = color
    return selected


def validate(payload, separation=.04, minimum_contrast=4.5, variant_distance=.08, variant_chroma=.02):
    if set(payload) != {'dark', 'light'} or payload['dark'] != payload['light']:
        raise ValueError('Static dark/light payloads must be identical')
    palette = payload['dark']
    expected = set(KEYS.values()) | {'terminal'}
    if set(palette) != expected:
        raise ValueError('Incomplete or unexpected palette roles')
    selected = {role: palette[KEYS[role]] for role in ROLES}
    for role, color in selected.items():
        if not isinstance(color, str) or not HEX.fullmatch(color):
            raise ValueError(f'Invalid final hex for {role}: {color}')
    for a, b in itertools.combinations(ROLES, 2):
        if distance(selected[a], selected[b]) < separation:
            raise ValueError(f'Collision: {a}/{b}')
    light = metrics(selected['surface'])[0][0] >= .6
    for role, color in selected.items():
        if not constraints(role, color, {r: c for r, c in selected.items() if ROLES.index(r) < ROLES.index(role)}, light, separation, minimum_contrast, variant_distance, variant_chroma):
            raise ValueError(f'Contrast or brightness conflict: {role}')
    validate_terminal(palette['terminal'])


def validate_terminal(terminal):
    if set(terminal) != {'normal', 'bright', 'foreground', 'background', 'cursor', 'cursorText', 'selectionFg', 'selectionBg'}:
        raise ValueError('Incomplete terminal palette')
    for section in ('normal', 'bright'):
        if set(terminal[section]) != {'black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white'}:
            raise ValueError(f'Incomplete terminal {section}')
    values = list(terminal['normal'].values()) + list(terminal['bright'].values()) + [v for v in terminal.values() if isinstance(v, str)]
    if len(values) != 22 or any(not isinstance(v, str) or not HEX.fullmatch(v) for v in values):
        raise ValueError('Invalid terminal hex')
