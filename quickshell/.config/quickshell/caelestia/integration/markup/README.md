Notification markup conversion is adapted from `~/builds/ward/src/NotificationPopup.cpp`
at commit `ca741094f1c09da4244b3782aa02580fba34e8bb`.
`ward-markup.cpp` retains Ward's XML parser, Pango span attributes, CSS variable
resolution, whitespace normalization, and escaped fallback for malformed markup.

`NotificationMarkup` exposes rich HTML, plain text, and a Qt StyledText preview.
The preview preserves colors and emphasis while allowing Qt to elide rendered
text. Expanded views use rich HTML for sizes, font families, backgrounds, and links.
Original notification strings remain available for history and copying.

Build with `scripts/build-integration` (`--dry-run` supported); the full
`scripts/build-runtime` also builds this module. Both install under `.runtime`.

Run the parser and preview regression checks from the Quickshell root:

```bash
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software /usr/lib/qt6/bin/qmltestrunner \
  -import "$PWD/.runtime/qml" -input caelestia/integration/markup/tests
```
