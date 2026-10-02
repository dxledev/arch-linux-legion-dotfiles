Static palettes are completed ahead of time by `generate-palettes`. Theme
switching continues to read `<theme>/noctalia.json` through the existing
Noctalia palette symlinks; it does not call this generator.

```bash
./noctalia/integration/generate-palettes                        # dry-run all
./noctalia/integration/generate-palettes --theme manga           # dry-run one
./noctalia/integration/generate-palettes --write                 # update stale caches
./noctalia/integration/generate-palettes --write --force         # regenerate all
./noctalia/integration/generate-palettes --min-distance 0.05     # stronger separation
```

`THEMES_DIR` and `NOCTALIA_BIN` override the source directory and installed
native executable. `--min-distance` defaults to `0.04` OKLab distance;
`--min-contrast` defaults to `4.5`. The corresponding environment defaults are
`NOCTALIA_PALETTE_MIN_DISTANCE` and `NOCTALIA_PALETTE_MIN_CONTRAST`. Values below
the required minimums are rejected.

`palette_cache.py` parses the original Colors.qml/Alacritty mappings (including
Qt ARGB colors, with alpha discarded for final RGB) and handles
fingerprints, locks, and publication. `palette_colors.py` handles final hex
conversion, comparison, swatches, selection, and validation. Role priority is:

```
primary → on_primary → secondary → on_secondary → tertiary → on_tertiary
→ error → on_error → surface → on_surface → surface_variant
→ on_surface_variant → outline → shadow → hover → on_hover
```

The shell surface is fixed to `waybar.css` background RGB (alpha is discarded).
It is reserved before selection, so colliding accents and foregrounds move
around it. Other valid original roles stay unchanged in the priority above.
The native `m3-content` generator reads deterministic combined and single-color
PNG swatches made from source theme colors. Its candidates are considered first,
then an OKLCH adjustment grid and local adjustments provide additional options.
Selection minimizes OKLab distance to the original among valid final hex
candidates, with native candidates preferred on ties, then lexicographic hex.
The search is finite: an unsatisfiable role fails explicitly rather than relaxing
separation, contrast, or priority. No Matugen or third-party Python packages are
required; Python 3.11 or newer supplies TOML parsing.

Surface lightness stays within OKLab L `[0.08, 0.45]` for dark themes and
`[0.75, 1.0]` for light themes (source surface L at least `0.6`). Shadow must have
lower luminance than surface. All 120 shell-role pairs and seven foreground
pairs are validated after quantization. Existing terminal blocks are preserved and are excluded from shell-role
uniqueness. Metadata keeps a terminal snapshot for recovery when palette JSON
is missing or corrupt; original source mappings are used only for a new cache.
Application configs and shared theme source files are never written. Dark/light payloads stay
identical.

`noctalia.meta.json` stores SHA-256 fingerprints of Colors.qml, alacritty.toml, and waybar.css, the Bash
entrypoint and Python helpers, settings, the native binary, and saved output.
Cache hits validate JSON, roles, contrast, separation, and terminal mappings
without invoking the native generator. Missing, stale, or corrupt caches
regenerate. Writes hold an adjacent `.noctalia.lock`, then fsync and atomically
replace each JSON file. Output is published before metadata; an interrupted
publication leaves either the old valid palette or the new validated palette,
and mismatched metadata triggers regeneration. Generation/validation failures
leave saved files intact. Dry-run uses only temporary swatches and never creates
palette, metadata, or lock files.

Run behavioral checks with:

```bash
PYTHONDONTWRITEBYTECODE=1 /usr/bin/python3 -m unittest discover -s noctalia/integration/tests -v
```

These checks cover color priority, readability, light and monochrome themes,
repeatability, dry-run preservation, cache hits, fingerprint invalidation,
corrupt/missing caches, generation failures, and competing writers. Native JSON
loading and rendered dropdown acceptance should be reported separately.

Surface variants stay within 0.08 OKLab distance of the original surface,
with chromatic shift limited to 0.02 to preserve neutral and pastel backgrounds.
Use `--variant-distance` and `--variant-chroma` to configure these limits;
they apply during selection and final cache validation.
