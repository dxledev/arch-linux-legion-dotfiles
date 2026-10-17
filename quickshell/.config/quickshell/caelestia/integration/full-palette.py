#!/usr/bin/env python3
"""Full ROYGBIV palette: reads a Dynamic palette on stdin, writes it back with a complete colour wheel.

Hues are fixed OKLCH anchors (red, orange, yellow, green, blue, indigo, violet). Lightness and chroma come from
the palette's own accents, so each variant keeps its character: Vibrant stays saturated, Monochrome and Neutral
stay muted. The anchors only lean a little toward the accent hue, which keeps the wheel recognisable and the
palette harmonious. The accents and surfaces are never rewritten, so applying the transform twice is a no-op.
"""
import json
import math
import sys

from palette_colour import colour_from_lab, lab, oklab_chroma

# Colour name -> (OKLCH hue in degrees, lightness level). The seven ROYGBIV colours come first. The renderer
# keeps every ANSI colour at least 0.06 apart in OKLab and swaps ones that sit closer, which would break the
# wheel. A search over lightness levels found the arrangement that keeps all twelve ANSI colours apart even at
# the lowest chroma: neighbouring hues alternate between levels 0 and 1, and each bright colour sits two levels
# on (lighter on dark themes, darker on light ones).
ROYGBIV = {
    "red": (29, 0),
    "peach": (58, 1),
    "yellow": (100, 1),
    "green": (145, 0),
    "blue": (262, 0),
    "lavender": (282, 2),
    "mauve": (308, 1),
}
# The rest of the wheel is rewritten only when the palette has these names, to match the seven above.
EXTRAS = {
    "maroon": (15, 2),
    "teal": (185, 1),
    "sky": (215, 2),
    "sapphire": (240, 1),
    "pink": (340, 2),
    "flamingo": (5, 3),
    "magenta": (330, 1),
    "cyan": (195, 1),
}
# ANSI colours: 1 red, 2 green, 3 yellow, 4 blue, 5 violet, 6 cyan; the bright ones sit two levels on.
TERMINAL = {1: "red", 2: "green", 3: "yellow", 4: "blue", 5: "mauve", 6: "teal"}
TERMINAL_HUES = {**{name: ROYGBIV[name] for name in ROYGBIV}, "teal": EXTRAS["teal"]}
BRIGHT_LEVELS = 2
LEVEL_STEP = 0.08

ACCENTS = ("primary", "secondary", "tertiary", "accent")
CHROMA_FLOOR = 0.07
CHROMA_CEILING = 0.14
# The lightness of level 1. Each level is LEVEL_STEP further toward white on dark themes, toward black on light ones.
LIGHTNESS_RANGE = {"dark": (0.70, 0.78), "light": (0.45, 0.55)}
HUE_PULL = 0.12
HUE_PULL_LIMIT = 10.0
MIN_ACCENT_CHROMA = 0.02


def hue_of(colour):
    _, a, b = lab(colour)
    return math.degrees(math.atan2(b, a)) % 360


def angle_between(start, end):
    return (end - start + 180) % 360 - 180


def build(colour_map, mode):
    accents = [colour_map[name] for name in ACCENTS if isinstance(colour_map.get(name), str)]
    if not accents:
        raise ValueError("palette has no accent colours")
    lightness = sum(lab(colour)[0] for colour in accents) / len(accents)
    low, high = LIGHTNESS_RANGE[mode]
    lightness = min(high, max(low, lightness))
    chroma = sum(oklab_chroma(colour) for colour in accents) / len(accents)
    chroma = min(CHROMA_CEILING, max(CHROMA_FLOOR, chroma * 1.4))
    lead = next((colour for colour in accents if oklab_chroma(colour) >= MIN_ACCENT_CHROMA), None)
    lead_hue = hue_of(lead) if lead else None

    # Dark themes climb toward white with each level, light ones toward black.
    direction = 1 if mode == "dark" else -1

    def make(hue_and_level, lift=0):
        hue, level = hue_and_level
        if lead_hue is not None:
            hue += max(-HUE_PULL_LIMIT, min(HUE_PULL_LIMIT, HUE_PULL * angle_between(hue, lead_hue)))
        radians = math.radians(hue)
        tone = lightness + direction * (level + lift - 1) * LEVEL_STEP
        return colour_from_lab(tone, chroma * math.cos(radians), chroma * math.sin(radians))

    return make


def transform(palette):
    colours = palette.get("colours")
    if not isinstance(colours, dict):
        raise ValueError("palette has no colours")
    mode = palette.get("mode")
    if mode not in LIGHTNESS_RANGE:
        raise ValueError("palette mode must be light or dark")
    sources = {key: value for key, value in colours.items() if isinstance(value, str)}
    make = build(sources, mode)
    result = dict(colours)
    for name, spec in ROYGBIV.items():
        result[name] = make(spec)
    for name, spec in EXTRAS.items():
        if name in colours:
            result[name] = make(spec)
    if "success" in colours:
        result["success"] = result["green"]
    for index, name in TERMINAL.items():
        result[f"term{index}"] = make(TERMINAL_HUES[name])
        result[f"term{index + 8}"] = make(TERMINAL_HUES[name], BRIGHT_LEVELS)
    return {**palette, "colours": result}


def main():
    try:
        palette = json.load(sys.stdin)
        output = transform(palette)
    except (ValueError, json.JSONDecodeError) as error:
        print(f"full-palette: {error}", file=sys.stderr)
        return 1
    json.dump(output, sys.stdout, ensure_ascii=False, separators=(",", ":"))
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
