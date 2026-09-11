import QtQuick
import QtTest
import Shell.Integration

TestCase {
    name: "NotificationMarkup"

    function test_themeNotification() {
        const result = NotificationMarkup.format('Updated to <b><span foreground="var(--primary-color)">Nord</span></b>.', {"--primary-color": "#88c0d0"});
        compare(result.plain, "Updated to Nord.");
        verify(result.html.includes("#ff88c0d0"));
        verify(result.preview.includes('<font color="#ff88c0d0"><b>Nord</b></font>'));
    }

    function test_pangoAttributes() {
        const result = NotificationMarkup.format('<span foreground="red" background="blue" font_family="monospace" weight="bold" style="italic" underline="single" strikethrough="true" size="14336">Styled</span>', {});
        compare(result.plain, "Styled");
        for (const style of ["color: #ffff0000", "background-color: #ff0000ff", "font-family:", "font-weight: bold", "font-style: italic", "text-decoration: underline", "line-through", "font-size: 14pt"])
            verify(result.html.includes(style), style);
    }

    function test_linesAndEntities() {
        const result = NotificationMarkup.format('One &amp; two\n<b>Three</b><br/>Four', {});
        compare(result.plain, "One & two\nThree\nFour");
        verify(!result.preview.includes("\n"));
        verify(result.preview.includes("&amp;"));
    }

    function test_literalAndMalformed_data() {
        return [{tag: "markdown", text: "a_b *literal* # heading [name]"},
                {tag: "comparison", text: "2 < 3 & 4 > 1"},
                {tag: "unclosed", text: "<b>Unclosed"},
                {tag: "mismatched", text: "<b>Bad</i>"}];
    }

    function test_literalAndMalformed(data) {
        compare(NotificationMarkup.format(data.text, {}).plain, data.text);
    }

    function test_nestedVariablesAndLinks() {
        const result = NotificationMarkup.format('<a href="https://example.com/?a=1&amp;b=2"><span color="var(--missing, var(--accent, red))">Link</span></a>', {"--accent": "#123456"});
        verify(result.html.includes("#ff123456"));
        verify(result.html.includes('href="https://example.com/?a=1&amp;b=2"'));
        compare(result.plain, "Link");
    }

    function test_unknownTagsAndSpacing() {
        compare(NotificationMarkup.format("<unknown>Text</unknown>\u00a0\u2060word", {}).plain, "Text word");
        compare(NotificationMarkup.format("", {}).html, "");
    }

    function test_previewElision() {
        const preview = Qt.createQmlObject('import QtQuick; Text { width: 80; textFormat: Text.StyledText; elide: Text.ElideRight; maximumLineCount: 1 }', this);
        preview.text = NotificationMarkup.format('<b><span color="red">A long styled notification title that should be elided</span></b>', {}).preview;
        verify(preview.truncated);
        verify(preview.contentWidth <= preview.width);
        preview.destroy();
    }
}
