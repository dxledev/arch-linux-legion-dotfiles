#!/usr/bin/env python3
import argparse
import json
import math
import os
import sys

from neovim_palette import build_palette
from palette_colour import contrast_ratio, luminance, oklab_chroma, oklab_distance, parse_colour

MUTED_MAX_CHROMA = 0.06
ANSI_BRIGHT_BLACK_CONTRAST = 1.5


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


def render_plan(palette, candidates, terminal, text_target, colour_target, distance_target, nvim_options=None):
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

    selected_neovim = build_palette(selected_terminal, background, palette.get("mode", "dark"),
                                    palette.get("variant", "default"), **(nvim_options or {}))

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
    lines.extend(selected_neovim["report"])

    return {"text": text, "terminal": selected_terminal, "neovim": selected_neovim, "report": lines}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--text-contrast", default=os.environ.get("THEME_RENDER_TEXT_CONTRAST", "4.5"))
    parser.add_argument("--color-contrast", default=os.environ.get("THEME_RENDER_COLOR_CONTRAST", "3"))
    parser.add_argument("--role-distance", default=os.environ.get("THEME_RENDER_ROLE_DISTANCE", "0.06"))
    parser.add_argument("--nvim-text-contrast", default=os.environ.get("THEME_RENDER_NVIM_TEXT_CONTRAST", "4.5"))
    parser.add_argument("--nvim-comment-contrast", default=os.environ.get("THEME_RENDER_NVIM_COMMENT_CONTRAST", "1.5"))
    parser.add_argument("--nvim-punctuation-contrast", default=os.environ.get("THEME_RENDER_NVIM_PUNCTUATION_CONTRAST", "3"))
    parser.add_argument("--nvim-comment-shade", default=os.environ.get("THEME_RENDER_NVIM_COMMENT_SHADE", "0.075"))
    parser.add_argument("--nvim-neutral-chroma", default=os.environ.get("THEME_RENDER_NVIM_NEUTRAL_CHROMA", "0.035"))
    parser.add_argument("--nvim-punctuation-darken", default=os.environ.get("THEME_RENDER_NVIM_PUNCTUATION_DARKEN", "0.10"))
    parser.add_argument("--nvim-comment-darken", default=os.environ.get("THEME_RENDER_NVIM_COMMENT_DARKEN", "0.225"))
    parser.add_argument("palette")
    args = parser.parse_args()

    try:
        text_target = finite_target("text contrast", args.text_contrast, 1)
        colour_target = finite_target("color contrast", args.color_contrast, 1)
        distance_target = finite_target("role distance", args.role_distance, 0)
        nvim_options = {
            "text_target": finite_target("Neovim text contrast", args.nvim_text_contrast, 1),
            "comment_target": finite_target("Neovim comment contrast", args.nvim_comment_contrast, 1),
            "punctuation_target": finite_target("Neovim punctuation contrast", args.nvim_punctuation_contrast, 1),
            "comment_shade": finite_target("Neovim comment shade", args.nvim_comment_shade, 0),
            "neutral_chroma": finite_target("Neovim neutral chroma", args.nvim_neutral_chroma, 0),
            "punctuation_darken": finite_target("Neovim punctuation darkening", args.nvim_punctuation_darken, 0),
            "comment_darken": finite_target("Neovim comment darkening", args.nvim_comment_darken, 0),
        }
        palette, candidates, terminal = load_palette(args.palette)
        print(json.dumps(render_plan(palette, candidates, terminal, text_target, colour_target, distance_target, nvim_options)))
    except (OSError, json.JSONDecodeError, KeyError, TypeError, ValueError) as error:
        print(f"contrast-palette: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
