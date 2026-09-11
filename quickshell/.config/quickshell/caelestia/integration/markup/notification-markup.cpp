#include "notification-markup.h"
#include "ward-markup.h"
#include <QTextBlock>
#include <QTextDocument>
#include <QTextFragment>

namespace {
QString styledFragment(const QTextFragment &fragment)
{
    const auto format = fragment.charFormat();
    QString text = fragment.text().toHtmlEscaped();
    if (format.fontWeight() >= QFont::Bold)
        text = "<b>" + text + "</b>";
    if (format.fontItalic())
        text = "<i>" + text + "</i>";
    if (format.fontUnderline())
        text = "<u>" + text + "</u>";
    if (format.fontStrikeOut())
        text = "<s>" + text + "</s>";
    if (format.hasProperty(QTextFormat::ForegroundBrush))
        text = "<font color=\"" + format.foreground().color().name(QColor::HexArgb) + "\">" + text + "</font>";
    return text;
}

QString styledPreview(const QTextDocument &document)
{
    QString text;
    for (auto block = document.begin(); block.isValid(); block = block.next()) {
        if (!text.isEmpty())
            text += ' ';
        for (auto it = block.begin(); !it.atEnd(); ++it)
            if (it.fragment().isValid())
                text += styledFragment(it.fragment());
    }
    return text.replace(QChar::LineSeparator, ' ');
}
}

QVariantMap NotificationMarkup::format(const QString &text, const QVariantMap &variables) const
{
    QHash<QString, QString> styles;
    for (auto it = variables.begin(); it != variables.end(); ++it)
        styles.insert(it.key(), it.value().toString());
    const auto html = richTextFromMarkup(text, styles);
    QTextDocument document;
    document.setHtml(html);
    return {{"html", html}, {"plain", document.toPlainText()}, {"preview", styledPreview(document)}};
}
