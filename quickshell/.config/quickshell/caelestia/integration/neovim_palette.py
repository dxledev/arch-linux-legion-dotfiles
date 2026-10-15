import math

from palette_colour import colour_from_lab, contrast_ratio, lab, oklab_chroma, parse_colour


ANSI_ROLES = {
    "red": 1, "green": 2, "yellow": 3, "peach": 3, "blue": 4, "primary": 4,
    "mauve": 5, "teal": 6, "secondary": 6, "pink": 13, "sky": 14, "lavender": 12,
}
SURFACE_NAMES = ("base", "mantle", "surface0", "surface1", "surface2")


def minimum_contrast(colour, backgrounds):
    return min(contrast_ratio(colour, background) for background in backgrounds)


def readable_colour(seed, backgrounds, target, dark_mode):
    if minimum_contrast(seed, backgrounds) >= target:
        return seed
    lightness, a, b = lab(seed)
    for endpoint in ((1.0, 0.0) if dark_mode else (0.0, 1.0)):
        best = colour_from_lab(endpoint, a, b)
        if minimum_contrast(best, backgrounds) < target:
            continue
        low, high = 0.0, 1.0
        for _ in range(24):
            amount = (low + high) / 2
            candidate = colour_from_lab(lightness + (endpoint - lightness) * amount, a, b)
            if minimum_contrast(candidate, backgrounds) >= target:
                best, high = candidate, amount
            else:
                low = amount
        return best
    raise ValueError(f"Neovim cannot reach {target:g}:1 contrast against its backgrounds")


def theme_tint(terminal, chroma_limit):
    neutral_seeds = [terminal[index] for index in (7, 15, 8, 0)]
    tinted = [colour for colour in neutral_seeds if 0.004 <= oklab_chroma(colour) <= 0.10]
    if tinted:
        _, a, b = lab(tinted[0])
    else:
        accents = [lab(terminal[index])[1:] for index in (1, 2, 3, 4, 5, 6)]
        a, b = (sum(pair[index] for pair in accents) / len(accents) for index in (0, 1))
        if math.hypot(a, b) < 0.004:
            _, a, b = lab(max(terminal, key=oklab_chroma))
    chroma = math.hypot(a, b)
    if chroma < 0.004:
        return 0.0, 0.0
    scale = min(chroma_limit, max(0.012, min(chroma, 0.025))) / chroma
    return a * scale, b * scale


def surface_palette(background, dark_mode, target):
    lightness, a, b = lab(background)
    direction = 1 if dark_mode else -1
    for step in (0.025, 0.0125, 0.0):
        colours = {"base": background, "mantle": colour_from_lab(lightness - direction * step, a, b)}
        for index, name in enumerate(SURFACE_NAMES[2:], 1):
            colours[name] = colour_from_lab(lightness + direction * step * index, a, b)
        backgrounds = list(colours.values())
        if any(minimum_contrast(endpoint, backgrounds) >= target for endpoint in ("000000", "ffffff")):
            return colours
    raise ValueError(f"Neovim cannot reach {target:g}:1 contrast with this terminal background")


def neutral_at(lightness, tint):
    return colour_from_lab(lightness, *tint)


def text_colour(terminal, backgrounds, tint, target, dark_mode):
    indices = (7, 15, 8, 0) if dark_mode else (0, 8, 7, 15)
    neutrals = [terminal[index] for index in indices]
    readable = [colour for colour in neutrals if minimum_contrast(colour, backgrounds) >= target]
    seed_lightness = lab((readable or neutrals)[0])[0]
    seed = neutral_at(min(0.97, max(0.03, seed_lightness)), tint)
    return readable_colour(seed, backgrounds, target, dark_mode)


def neutral_pair(backgrounds, tint, text, text_target, comment_target, shade, dark_mode, report):
    seed_lightness = lab(text)[0] - 0.18 if dark_mode else lab(text)[0] + 0.18
    comment = readable_colour(neutral_at(seed_lightness - shade, tint), backgrounds, comment_target, dark_mode)
    punctuation = readable_colour(neutral_at(lab(comment)[0] + shade, tint), backgrounds, text_target, dark_mode)
    desired_comment = neutral_at(lab(punctuation)[0] - shade, tint)
    if minimum_contrast(desired_comment, backgrounds) >= comment_target:
        comment = desired_comment
    gap = lab(punctuation)[0] - lab(comment)[0]
    if abs(gap - shade) > 0.006:
        report.append(f"Neovim comment shade clamped: requested {shade:.3f}, available {gap:.3f} OKLab lightness")
    if gap < -0.003:
        raise ValueError("Neovim comments cannot be darker than punctuation at the requested contrast")
    return punctuation, comment


def darken_neutral(colour, amount, backgrounds, target, dark_mode, role, report):
    lightness, a, b = lab(colour)
    desired = colour_from_lab(lightness - amount, a, b)
    adjusted = readable_colour(desired, backgrounds, target, dark_mode)
    actual = lightness - lab(adjusted)[0]
    if abs(actual - amount) > 0.006:
        report.append(f"Neovim {role} darkening clamped: requested {amount:.3f}, available {actual:.3f} OKLab lightness")
    return adjusted


def build_palette(terminal, background, mode, variant, text_target=4.5,
                  comment_target=1.5, comment_shade=0.075, neutral_chroma=0.035,
                  punctuation_darken=0.10, comment_darken=0.225, punctuation_target=3.0):
    terminal = [parse_colour(colour) for colour in terminal]
    if len(terminal) != 16 or mode not in ("dark", "light"):
        raise ValueError("Neovim requires sixteen ANSI colours and a dark or light mode")
    if not isinstance(variant, str):
        raise ValueError("Neovim variant must be a string")
    background = parse_colour(background)
    dark_mode = mode == "dark"
    report = []
    colours = surface_palette(background, dark_mode, max(text_target, comment_target, punctuation_target))
    backgrounds = [colours[name] for name in SURFACE_NAMES]
    tint = theme_tint(terminal, neutral_chroma)
    colours["text"] = text_colour(terminal, backgrounds, tint, text_target, dark_mode)
    punctuation, comment = neutral_pair(backgrounds, tint, colours["text"], text_target,
                                        max(text_target, comment_target), comment_shade, dark_mode, report)
    punctuation = darken_neutral(punctuation, punctuation_darken, backgrounds, punctuation_target,
                                 dark_mode, "punctuation", report)
    comment = darken_neutral(comment, comment_darken, backgrounds, comment_target,
                            dark_mode, "comment", report)
    colours.update(punctuation=punctuation, muted=comment, subtext0=comment, subtext1=punctuation,
                   overlay0=punctuation, overlay1=punctuation, selection_text=background)
    for name, index in ANSI_ROLES.items():
        colours[name] = readable_colour(terminal[index], backgrounds, text_target, dark_mode)
        if colours[name] != terminal[index]:
            report.append(f"Neovim {name}: ANSI {index} #{terminal[index]} -> #{colours[name]} (contrast correction)")
    report.append(f"Neovim: terminal ANSI seeds, {mode}/{variant}, text >= {text_target:g}:1, punctuation >= {punctuation_target:g}:1, comments >= {comment_target:g}:1")
    return {"colours": colours, "terminal": terminal, "mode": mode, "variant": variant, "report": report}
