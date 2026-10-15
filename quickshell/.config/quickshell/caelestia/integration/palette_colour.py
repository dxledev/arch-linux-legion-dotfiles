import math
import re


HEX_PATTERN = re.compile(r"^#?([0-9a-fA-F]{6})$")


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


def oklab_channels(lightness, a, b):
    light = (lightness + 0.3963377774 * a + 0.2158037573 * b) ** 3
    middle = (lightness - 0.1055613458 * a - 0.0638541728 * b) ** 3
    short = (lightness - 0.0894841775 * a - 1.2914855480 * b) ** 3
    return (
        4.0767416621 * light - 3.3077115913 * middle + 0.2309699292 * short,
        -1.2684380046 * light + 2.6097574011 * middle - 0.3413193965 * short,
        -0.0041960863 * light - 0.7034186147 * middle + 1.7076147010 * short,
    )


def colour_from_lab(lightness, a, b):
    lightness = min(1.0, max(0.0, lightness))
    low, high = 0.0, 1.0
    for _ in range(24):
        channels = oklab_channels(lightness, a * high, b * high)
        if all(-1e-9 <= channel <= 1 + 1e-9 for channel in channels):
            break
        middle = (low + high) / 2
        channels = oklab_channels(lightness, a * middle, b * middle)
        if all(0 <= channel <= 1 for channel in channels):
            low = middle
        else:
            high = middle
    channels = oklab_channels(lightness, a * low if high < 1 else a, b * low if high < 1 else b)
    encoded = (12.92 * value if value <= 0.0031308 else 1.055 * value ** (1 / 2.4) - 0.055 for value in channels)
    return "".join(f"{min(255, max(0, round(value * 255))):02x}" for value in encoded)
