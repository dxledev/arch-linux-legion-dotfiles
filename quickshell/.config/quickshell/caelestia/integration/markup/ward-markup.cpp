#include "ward-markup.h"
#include <QColor>
#include <QXmlStreamReader>

namespace {
QString resolveStyleValue(const QString &, const QHash<QString, QString> &, int depth = 0);

QString textDecorationStyle(const QString &value)
{
    const QString lowered = value.trimmed().toLower();
    if (lowered == "single" || lowered == "true" || lowered == "yes") {
        return QStringLiteral("text-decoration: underline;");
    }
    if (lowered == "double") {
        return QStringLiteral("text-decoration: underline double;");
    }
    if (lowered == "error") {
        return QStringLiteral("text-decoration: underline wavy;");
    }
    return {};
}

QString sizeStyle(const QString &value)
{
    const QString trimmed = value.trimmed().toLower();
    if (trimmed.isEmpty()) {
        return {};
    }

    if (trimmed == "xx-small" || trimmed == "x-small" || trimmed == "small" ||
        trimmed == "medium" || trimmed == "large" || trimmed == "x-large" ||
        trimmed == "xx-large" || trimmed == "smaller" || trimmed == "larger") {
        return QStringLiteral("font-size: %1;").arg(trimmed);
    }

    bool ok = false;
    const int numericSize = trimmed.toInt(&ok);
    if (!ok) {
        return {};
    }

    if (numericSize > 1024) {
        return QStringLiteral("font-size: %1pt;").arg(numericSize / 1024);
    }

    return QStringLiteral("font-size: %1pt;").arg(numericSize);
}

QString stripEnclosingQuotes(const QString &value)
{
    const QString trimmed = value.trimmed();
    if (trimmed.size() < 2) {
        return trimmed;
    }

    const QChar first = trimmed.front();
    const QChar last = trimmed.back();
    if ((first == '\'' && last == '\'') || (first == '"' && last == '"')) {
        return trimmed.mid(1, trimmed.size() - 2);
    }

    return trimmed;
}

int matchingParenthesisIndex(const QString &value, int openIndex)
{
    int depth = 0;
    QChar quote;

    for (int index = openIndex; index < value.size(); ++index) {
        const QChar character = value.at(index);

        if (!quote.isNull()) {
            if (character == quote && (index == 0 || value.at(index - 1) != '\\')) {
                quote = QChar();
            }
            continue;
        }

        if (character == '\'' || character == '"') {
            quote = character;
            continue;
        }

        if (character == '(') {
            ++depth;
            continue;
        }

        if (character != ')') {
            continue;
        }

        --depth;
        if (depth == 0) {
            return index;
        }
    }

    return -1;
}

int topLevelCommaIndex(const QString &value)
{
    int depth = 0;
    QChar quote;

    for (int index = 0; index < value.size(); ++index) {
        const QChar character = value.at(index);

        if (!quote.isNull()) {
            if (character == quote && (index == 0 || value.at(index - 1) != '\\')) {
                quote = QChar();
            }
            continue;
        }

        if (character == '\'' || character == '"') {
            quote = character;
            continue;
        }

        if (character == '(') {
            ++depth;
            continue;
        }

        if (character == ')') {
            depth = qMax(0, depth - 1);
            continue;
        }

        if (character == ',' && depth == 0) {
            return index;
        }
    }

    return -1;
}

QString resolveStyleValue(const QString &value,
                          const QHash<QString, QString> &styleVariables,
                          int depth)
{
    QString resolved = value;
    if (depth > 16 || !resolved.contains(QStringLiteral("var("))) {
        return resolved.trimmed();
    }

    int searchFrom = 0;
    while (true) {
        const int varIndex = resolved.indexOf(QStringLiteral("var("), searchFrom);
        if (varIndex < 0) {
            break;
        }

        const int openIndex = varIndex + 3;
        const int closeIndex = matchingParenthesisIndex(resolved, openIndex);
        if (closeIndex < 0) {
            break;
        }

        const QString arguments = resolved.mid(openIndex + 1, closeIndex - openIndex - 1).trimmed();
        const int commaIndex = topLevelCommaIndex(arguments);
        const QString variableName =
            (commaIndex < 0 ? arguments : arguments.left(commaIndex)).trimmed();
        const QString fallback =
            commaIndex < 0 ? QString() : arguments.mid(commaIndex + 1).trimmed();

        QString replacement;
        if (styleVariables.contains(variableName)) {
            replacement = resolveStyleValue(styleVariables.value(variableName), styleVariables, depth + 1);
        } else if (!fallback.isEmpty()) {
            replacement = resolveStyleValue(fallback, styleVariables, depth + 1);
        }

        resolved.replace(varIndex, closeIndex - varIndex + 1, replacement);
        searchFrom = varIndex + replacement.size();
    }

    return resolved.trimmed();
}

QString resolvedAttributeValue(const QXmlStreamAttributes &attributes,
                               const QStringList &keys,
                               const QHash<QString, QString> &styleVariables)
{
    for (const QString &key : keys) {
        if (!attributes.hasAttribute(key)) {
            continue;
        }

        return resolveStyleValue(attributes.value(key).toString(), styleVariables);
    }

    return {};
}

QColor colorFromStyleValue(const QString &value)
{
    return QColor(value.trimmed());
}

QString spanStyle(const QXmlStreamAttributes &attributes, const QHash<QString, QString> &styleVariables)
{
    QStringList styles;

    const auto addColorStyle = [&styles, &attributes, &styleVariables](const QString &key, const QString &cssKey) {
        if (!attributes.hasAttribute(key)) {
            return;
        }

        const QString resolvedValue = resolveStyleValue(attributes.value(key).toString(), styleVariables);
        const QColor color = colorFromStyleValue(resolvedValue);
        if (color.isValid()) {
            styles.append(QStringLiteral("%1: %2;").arg(cssKey, color.name(QColor::HexArgb)));
        }
    };

    addColorStyle(QStringLiteral("foreground"), QStringLiteral("color"));
    addColorStyle(QStringLiteral("fgcolor"), QStringLiteral("color"));
    addColorStyle(QStringLiteral("color"), QStringLiteral("color"));
    addColorStyle(QStringLiteral("background"), QStringLiteral("background-color"));
    addColorStyle(QStringLiteral("bgcolor"), QStringLiteral("background-color"));

    if (attributes.hasAttribute(QStringLiteral("font_family"))) {
        const QString family = stripEnclosingQuotes(resolveStyleValue(
            attributes.value(QStringLiteral("font_family")).toString(),
            styleVariables));
        if (!family.isEmpty()) {
            styles.append(QStringLiteral("font-family: '%1';").arg(family.toHtmlEscaped()));
        }
    } else if (attributes.hasAttribute(QStringLiteral("face"))) {
        const QString family = stripEnclosingQuotes(resolveStyleValue(
            attributes.value(QStringLiteral("face")).toString(),
            styleVariables));
        if (!family.isEmpty()) {
            styles.append(QStringLiteral("font-family: '%1';").arg(family.toHtmlEscaped()));
        }
    }

    const QString fontWeight = resolvedAttributeValue(attributes,
                                                      {
                                                          QStringLiteral("font_weight"),
                                                          QStringLiteral("font-weight"),
                                                          QStringLiteral("weight")
                                                      },
                                                      styleVariables);
    if (!fontWeight.isEmpty()) {
        styles.append(QStringLiteral("font-weight: %1;").arg(fontWeight.toHtmlEscaped()));
    }

    if (attributes.hasAttribute(QStringLiteral("font_style"))) {
        const QString fontStyle = resolveStyleValue(attributes.value(QStringLiteral("font_style")).toString(),
                                                    styleVariables);
        if (!fontStyle.isEmpty()) {
            styles.append(QStringLiteral("font-style: %1;").arg(fontStyle.toHtmlEscaped()));
        }
    } else if (attributes.hasAttribute(QStringLiteral("style"))) {
        const QString fontStyle = resolveStyleValue(attributes.value(QStringLiteral("style")).toString(),
                                                    styleVariables);
        if (!fontStyle.isEmpty()) {
            styles.append(QStringLiteral("font-style: %1;").arg(fontStyle.toHtmlEscaped()));
        }
    }

    if (attributes.hasAttribute(QStringLiteral("underline"))) {
        const QString underlineStyle = textDecorationStyle(
            attributes.value(QStringLiteral("underline")).toString());
        if (!underlineStyle.isEmpty()) {
            styles.append(underlineStyle);
        }
    }

    if (attributes.hasAttribute(QStringLiteral("strikethrough"))) {
        const QString lowered =
            attributes.value(QStringLiteral("strikethrough")).toString().trimmed().toLower();
        if (lowered == "true" || lowered == "yes" || lowered == "single") {
            styles.append(QStringLiteral("text-decoration: line-through;"));
        }
    }

    if (attributes.hasAttribute(QStringLiteral("size"))) {
        const QString style = sizeStyle(resolveStyleValue(attributes.value(QStringLiteral("size")).toString(),
                                                          styleVariables));
        if (!style.isEmpty()) {
            styles.append(style);
        }
    } else if (attributes.hasAttribute(QStringLiteral("font_size"))) {
        const QString style = sizeStyle(resolveStyleValue(
            attributes.value(QStringLiteral("font_size")).toString(),
            styleVariables));
        if (!style.isEmpty()) {
            styles.append(style);
        }
    }

    return styles.join(' ');
}

}

QString richTextFromMarkup(const QString &text,
                           const QHash<QString, QString> &styleVariables)
{
    if (text.trimmed().isEmpty()) {
        return {};
    }

    QXmlStreamReader xml(QStringLiteral("<root>%1</root>").arg(text));
    QString html;
    QStringList closingTags;

    while (!xml.atEnd()) {
        switch (xml.readNext()) {
        case QXmlStreamReader::StartElement: {
            const QString name = xml.name().toString().toLower();
            if (name == QStringLiteral("root")) {
                closingTags.prepend({});
                break;
            }

            if (name == QStringLiteral("b") || name == QStringLiteral("big") ||
                name == QStringLiteral("i") || name == QStringLiteral("small") ||
                name == QStringLiteral("sub") || name == QStringLiteral("sup")) {
                html += QStringLiteral("<%1>").arg(name);
                closingTags.prepend(QStringLiteral("</%1>").arg(name));
                break;
            }

            if (name == QStringLiteral("tt")) {
                html += QStringLiteral("<code>");
                closingTags.prepend(QStringLiteral("</code>"));
                break;
            }

            if (name == QStringLiteral("u")) {
                html += QStringLiteral("<span style=\"text-decoration: underline;\">");
                closingTags.prepend(QStringLiteral("</span>"));
                break;
            }

            if (name == QStringLiteral("s") || name == QStringLiteral("strike") ||
                name == QStringLiteral("strikethrough")) {
                html += QStringLiteral("<span style=\"text-decoration: line-through;\">");
                closingTags.prepend(QStringLiteral("</span>"));
                break;
            }

            if (name == QStringLiteral("span")) {
                const QString style = spanStyle(xml.attributes(), styleVariables).toHtmlEscaped();
                if (style.isEmpty()) {
                    html += QStringLiteral("<span>");
                } else {
                    html += QStringLiteral("<span style=\"%1\">").arg(style);
                }
                closingTags.prepend(QStringLiteral("</span>"));
                break;
            }

            if (name == QStringLiteral("a")) {
                const QString href = xml.attributes().value(QStringLiteral("href")).toString().toHtmlEscaped();
                html += QStringLiteral("<a href=\"%1\">").arg(href);
                closingTags.prepend(QStringLiteral("</a>"));
                break;
            }

            if (name == QStringLiteral("br")) {
                html += QStringLiteral("<br/>");
                closingTags.prepend({});
                break;
            }

            closingTags.prepend({});
            break;
        }
        case QXmlStreamReader::EndElement:
            if (!closingTags.isEmpty()) {
                html += closingTags.takeFirst();
            }
            break;
        case QXmlStreamReader::Characters:
        {
            QString characters = xml.text().toString();
            characters.replace(QChar::Nbsp, QLatin1Char(' '));
            characters.replace(QChar(0x202F), QLatin1Char(' '));
            characters.replace(QChar(0x2007), QLatin1Char(' '));
            characters.replace(QChar(0xFEFF), QLatin1Char(' '));
            characters.remove(QChar(0x2060));
            html += characters.toHtmlEscaped().replace('\n', QStringLiteral("<br/>"));
            break;
        }
        default:
            break;
        }
    }

    if (xml.hasError()) {
        QString escapedText = text;
        escapedText.replace(QChar::Nbsp, QLatin1Char(' '));
        escapedText.replace(QChar(0x202F), QLatin1Char(' '));
        escapedText.replace(QChar(0x2007), QLatin1Char(' '));
        escapedText.replace(QChar(0xFEFF), QLatin1Char(' '));
        escapedText.remove(QChar(0x2060));
        return escapedText.toHtmlEscaped().replace('\n', QStringLiteral("<br/>"));
    }

    return html;
}

