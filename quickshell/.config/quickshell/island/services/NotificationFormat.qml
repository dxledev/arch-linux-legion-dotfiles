pragma Singleton

import QtQuick
import Shell.Integration
import "../styles"

// Converts Pango notification markup with the parser shared with Caelestia
// (caelestia/integration/markup). Stored summary/body strings stay raw so the
// shared history keeps the original text; only the display layer formats them.
QtObject {
    id: root

    readonly property var variables: ({
        "--background": Theme.background,
        "--backgroundAlt": Theme.surface,
        "--backgroundAlpha": Theme.card,
        "--backgroundGray": Theme.surfaceVariant,
        "--foreground": Theme.textPrimary,
        "--foregroundInactive": Theme.textSecondary,
        "--primary": Theme.accent,
        "--muted": Theme.textMuted,
        "--border": Theme.border,
        "--secondary": Theme.textSecondary,
        "--success": Theme.success,
        "--warning": Theme.warning,
        "--danger": Theme.danger,
        "--accent": Theme.accent,
        "--text-color": Theme.textPrimary,
        "--primary-color": Theme.accent,
        "--secondary-color": Theme.textSecondary,
        "--border-color": Theme.border
    })

    // Returns {html, plain, preview}: html for RichText, preview for elided StyledText.
    function format(text: string): var {
        return NotificationMarkup.format(text ?? "", variables);
    }

    // Like format(), but the preview keeps line breaks (e.g. title then artist on
    // separate lines). Each line is converted on its own so StyledText can still
    // elide and cap the line count.
    function formatLines(text: string): var {
        const whole = format(text);
        const lines = (text ?? "").split(/\n|<br\s*\/?>/i).filter(line => line.trim().length > 0);
        if (lines.length < 2) return Object.assign({lines: lines.length}, whole);
        return {lines: lines.length, html: whole.html, plain: whole.plain, preview: lines.map(line => format(line).preview).join("<br/>")};
    }
}
