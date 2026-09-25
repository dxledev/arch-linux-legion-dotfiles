#!/usr/bin/env python3
import argparse
import json
import math
import os
import re
import sys


HEX_PATTERN = re.compile(r"^#?([0-9a-fA-F]{6})$")
MUTED_MAX_CHROMA = 0.06
MUTED_CONTRAST_TARGET = 3.0
ANSI_BRIGHT_BLACK_CONTRAST = 1.5
SYNTAX_ROLES = (
    ("subtext", "subtext0"),
    ("constant", "peach"),
    ("string", "green"),
    ("function", "blue"),
    ("keyword", "mauve"),
    ("preprocessor", "pink"),
    ("type", "teal"),
    ("special", "sky"),
    ("delimiter", "subtext1"),
)


def parse_colour(value):
    match = HEX_PATTERN.fullmatch(str(value))
    if not match:
        raise ValueError(f"invalid colour: {value}")
    return match.group(1).lower()


def rgb(colour):
    value = parse_colour(colour)
    return tuple(int(value[index : index + 2], 16) / 255 for index in (0, 2, 4))


def linear_channel(value):
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def luminance(colour):
    red, green, blue = (linear_channel(channel) for channel in rgb(colour))
    return 0.2126 * red + 0.7152 * green + 0.0722 * blue


def contrast_ratio(first, second):
    high, low = sorted((luminance(first), luminance(second)), reverse=True)
    return (high + 0.05) / (low + 0.05)


def lab(colour):
    red, green, blue = (linear_channel(channel) for channel in rgb(colour))
    lightness_root = 0.4122214708 * red + 0.5363325363 * green + 0.0514459929 * blue
    green_root = 0.2119034982 * red + 0.6806995451 * green + 0.1073969566 * blue
    blue_root = 0.0883024619 * red + 0.2817188376 * green + 0.6299787005 * blue
    lightness_root, green_root, blue_root = (value ** (1 / 3) for value in (lightness_root, green_root, blue_root))
    return (
        0.2104542553 * lightness_root + 0.7936177850 * green_root - 0.0040720468 * blue_root,
        1.9779984951 * lightness_root - 2.4285922050 * green_root + 0.4505937099 * blue_root,
        0.0259040371 * lightness_root + 0.7827717662 * green_root - 0.8086757660 * blue_root,
    )


def oklab_distance(first, second):
    return math.dist(lab(first), lab(second))


def oklab_chroma(colour):
    _, a, b = lab(colour)
    return math.hypot(a, b)


def minimum_separation(colour, assigned):
    if not assigned:
        return math.inf
    return min(oklab_distance(colour, other) for other in assigned)


def choose_replacement(original, background, candidates, assigned, contrast_target, distance_target, contrast_priority=False):
    measures = [
        (
            candidate,
            contrast_ratio(candidate, background),
            minimum_separation(candidate, assigned),
            oklab_distance(candidate, original),
        )
        for candidate in candidates
    ]
    if not measures:
        return original

    passing = [
        item for item in measures
        if item[1] >= contrast_target and item[2] >= distance_target
    ]
    if passing:
        return min(passing, key=lambda item: (item[3], -item[1], -item[2], item[0]))[0]

    if contrast_priority:
        readable = [item for item in measures if item[1] >= contrast_target]
        if readable:
            return min(readable, key=lambda item: (-item[2], item[3], -item[1], item[0]))[0]
    else:
        available = [item for item in measures if item[0] not in assigned] or measures
        readable = [item for item in available if item[1] >= contrast_target]
        pool = readable or available
        return min(pool, key=lambda item: (-item[1], -item[2], item[3], item[0]))[0]

    separated = [item for item in measures if item[2] >= distance_target]
    if separated:
        return min(separated, key=lambda item: (-item[1], item[3], -item[2], item[0]))[0]

    distinct = [item for item in measures if item[2] > 1e-9]
    fallback = distinct or measures
    return min(fallback, key=lambda item: (-item[1], -item[2], item[3], item[0]))[0]


def apply_role(role, source_key, palette, background, candidates, assigned, contrast_target, distance_target, changes, unmet, contrast_priority=False):
    original = parse_colour(palette[source_key])
    contrast = contrast_ratio(original, background)
    separation = minimum_separation(original, assigned)
    colour = original
    if contrast < contrast_target or separation < distance_target:
        colour = choose_replacement(
            original, background, candidates, assigned, contrast_target, distance_target, contrast_priority
        )

    final_contrast = contrast_ratio(colour, background)
    final_separation = minimum_separation(colour, assigned)
    assigned.append(colour)
    if colour != original:
        separation_report = f", separation {final_separation:.3f}" if math.isfinite(final_separation) else ""
        changes.append(
            f"{role}: #{original} -> #{colour} (contrast {final_contrast:.2f}:1{separation_report})"
        )
    if final_contrast < contrast_target:
        unmet.append(f"{role}: contrast {final_contrast:.2f}:1 below {contrast_target:.2f}:1")
    if final_separation < distance_target:
        unmet.append(f"{role}: separation {final_separation:.3f} below {distance_target:.3f}")
    return colour


def load_palette(path):
    with open(path, encoding="utf-8") as palette_file:
        palette = json.load(palette_file)
    source_colours = palette.get("source_colours")
    if not isinstance(source_colours, list) or not source_colours:
        raise ValueError("palette must include a non-empty source_colours array")
    candidates = list(dict.fromkeys(parse_colour(value) for value in source_colours))
    terminal = palette.get("terminal")
    if not isinstance(terminal, list) or len(terminal) != 16:
        raise ValueError("palette must include exactly 16 terminal colours")
    return palette, candidates, [parse_colour(value) for value in terminal]


def select_muted_colour(original, background, candidates, contrast_target):
    original = parse_colour(original)
    original_contrast = contrast_ratio(original, background)
    original_chroma = oklab_chroma(original)
    if original_contrast >= contrast_target and original_chroma <= MUTED_MAX_CHROMA:
        return original, None

    measures = [
        (candidate, contrast_ratio(candidate, background), oklab_chroma(candidate))
        for candidate in candidates
    ]
    muted = [item for item in measures if item[1] >= contrast_target and item[2] <= MUTED_MAX_CHROMA]
    if muted:
        selected = min(muted, key=lambda item: (item[1], item[2], item[0]))
        return selected[0], None

    readable = [item for item in measures if item[1] >= contrast_target]
    if readable:
        selected = min(readable, key=lambda item: (item[2], item[1], item[0]))
    else:
        selected = min(measures, key=lambda item: (item[2], -item[1], item[0]))
    warning = (
        "Neovim muted: no source colour meets both "
        f"{contrast_target:.2f}:1 contrast and OKLab chroma <= {MUTED_MAX_CHROMA:.3f}; "
        f"selected #{selected[0]} at {selected[1]:.2f}:1"
    )
    return selected[0], warning


def select_ansi_blacks(candidates, background, dark_mode):
    distinct = sorted(set(candidates), key=lambda colour: (luminance(colour), colour))
    if len(distinct) < 2:
        raise ValueError("palette must include at least two distinct source colours for ANSI black slots")
    if not dark_mode:
        return distinct[:2]

    readable = [
        colour for colour in distinct[1:]
        if contrast_ratio(colour, background) >= ANSI_BRIGHT_BLACK_CONTRAST
    ]
    subdued = [colour for colour in readable if oklab_chroma(colour) <= MUTED_MAX_CHROMA]
    candidates_for_bright_black = subdued or readable
    bright_black = candidates_for_bright_black[0] if candidates_for_bright_black else distinct[1]
    return [distinct[0], bright_black]


def finite_target(name, value, minimum):
    target = float(value)
    if not math.isfinite(target) or target < minimum:
        raise ValueError(f"{name} must be a finite number at least {minimum}")
    return target


def render_plan(palette, candidates, terminal, text_target, colour_target, distance_target):
    colours = palette.get("colours", palette)
    background = parse_colour(colours["base"])
    changes = []
    unmet = []

    text = parse_colour(colours["text"])
    if contrast_ratio(text, background) < text_target:
        replacement = choose_replacement(text, background, candidates, [], text_target, 0)
        if replacement != text:
            changes.append(
                f"text: #{text} -> #{replacement} (contrast {contrast_ratio(replacement, background):.2f}:1)"
            )
        text = replacement
    text_contrast = contrast_ratio(text, background)
    if text_contrast < text_target:
        unmet.append(f"text: contrast {text_contrast:.2f}:1 below {text_target:.2f}:1")

    ansi_names = ("black", "red", "green", "yellow", "blue", "magenta", "cyan", "white") * 2
    selected_terminal = [None] * 16
    dark_mode = str(palette.get("mode", "dark")).lower() == "dark"
    black_colours = select_ansi_blacks(
        candidates, background, dark_mode
    )
    assigned = list(black_colours)
    for index, colour in ((0, black_colours[0]), (8, black_colours[1])):
        selected_terminal[index] = colour
        if colour != terminal[index]:
            if index == 8 and dark_mode:
                ratio = contrast_ratio(colour, background)
                if ratio < ANSI_BRIGHT_BLACK_CONTRAST:
                    description = "dark fallback source colour"
                elif oklab_chroma(colour) <= MUTED_MAX_CHROMA:
                    description = "subdued dark source colour"
                else:
                    description = "dark source colour"
                reason = f"reserved {description}; contrast {ratio:.2f}:1"
                if ratio < ANSI_BRIGHT_BLACK_CONTRAST:
                    reason += f" below {ANSI_BRIGHT_BLACK_CONTRAST:.2f}:1 visibility preference"
            elif index == 8:
                reason = "reserved second darkest source colour"
            else:
                reason = "reserved darkest source colour"
            changes.append(f"ANSI {ansi_names[index]}[{index}]: #{terminal[index]} -> #{colour} ({reason})")

    for index, original in enumerate(terminal):
        if index in (0, 8):
            continue
        colour = apply_role(
            f"ANSI {ansi_names[index]}[{index}]",
            "terminal",
            {"terminal": original},
            background,
            candidates,
            assigned,
            colour_target,
            distance_target,
            changes,
            unmet,
        )
        selected_terminal[index] = colour

    selected_neovim = {}
    assigned = [*selected_terminal, text]
    for role, source_key in SYNTAX_ROLES:
        selected_neovim[source_key] = apply_role(
            f"Neovim {role}",
            source_key,
            colours,
            background,
            candidates,
            assigned,
            colour_target,
            distance_target,
            changes,
            unmet,
            contrast_priority=True,
        )

    for role, source_key in (("error", "red"), ("warning", "yellow"), ("accent", "primary")):
        selected_neovim[source_key] = apply_role(
            f"Neovim {role}",
            source_key,
            colours,
            background,
            candidates,
            assigned,
            colour_target,
            distance_target,
            changes,
            unmet,
            contrast_priority=True,
        )

    muted_colour, muted_warning = select_muted_colour(
        colours["subtext0"], background, candidates, MUTED_CONTRAST_TARGET
    )
    selected_neovim["muted"] = muted_colour
    if muted_colour != parse_colour(colours["subtext0"]):
        changes.append(
            f"Neovim muted: #{parse_colour(colours['subtext0'])} -> #{muted_colour} "
            f"(contrast {contrast_ratio(muted_colour, background):.2f}:1, "
            f"chroma {oklab_chroma(muted_colour):.3f})"
        )
    if muted_warning:
        unmet.append(muted_warning)

    lines = ["Dynamic contrast report"]
    if changes:
        lines.append("Changed roles:")
        lines.extend(f"- {line}" for line in changes)
    else:
        lines.append("Changed roles: none")
    if unmet:
        lines.append("Unmet targets:")
        lines.extend(f"- {line}" for line in unmet)
    else:
        lines.append("Unmet targets: none")

    return {"text": text, "terminal": selected_terminal, "neovim": selected_neovim, "report": lines}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--text-contrast", default=os.environ.get("THEME_RENDER_TEXT_CONTRAST", "4.5"))
    parser.add_argument("--color-contrast", default=os.environ.get("THEME_RENDER_COLOR_CONTRAST", "3"))
    parser.add_argument("--role-distance", default=os.environ.get("THEME_RENDER_ROLE_DISTANCE", "0.06"))
    parser.add_argument("palette")
    args = parser.parse_args()

    try:
        text_target = finite_target("text contrast", args.text_contrast, 1)
        colour_target = finite_target("color contrast", args.color_contrast, 1)
        distance_target = finite_target("role distance", args.role_distance, 0)
        palette, candidates, terminal = load_palette(args.palette)
        print(json.dumps(render_plan(palette, candidates, terminal, text_target, colour_target, distance_target)))
    except (OSError, json.JSONDecodeError, KeyError, TypeError, ValueError) as error:
        print(f"contrast-palette: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
