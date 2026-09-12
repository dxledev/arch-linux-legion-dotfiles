#pragma once
#include <QColor>
#include <QDir>
#include <QEasingCurve>
#include <QFileInfo>
#include <QHash>
#include <QRegularExpression>
#include <QStandardPaths>
#include <cmath>
#include <unistd.h>

namespace ChromackColors {
constexpr int kMaterialSwatchGapPx = 2;
constexpr int kMaterialGridColumns = 16;
constexpr int kMaterialGridRows = 3;
constexpr int kRecentColorSlots = kMaterialGridColumns;

QString materialPaletteKey(int index)
{
    return QStringLiteral("--color-material-%1").arg(index + 1, 2, 10, QLatin1Char('0'));
}

const QStringList &materialPaletteColors()
{
    static const QStringList colors = {
        QStringLiteral("#f44336"), QStringLiteral("#e91e63"), QStringLiteral("#9c27b0"), QStringLiteral("#673ab7"),
        QStringLiteral("#3f51b5"), QStringLiteral("#2196f3"), QStringLiteral("#03a9f4"), QStringLiteral("#00bcd4"),
        QStringLiteral("#009688"), QStringLiteral("#4caf50"), QStringLiteral("#8bc34a"), QStringLiteral("#cddc39"),
        QStringLiteral("#ffeb3b"), QStringLiteral("#ffc107"), QStringLiteral("#ff9800"), QStringLiteral("#ff5722"),
        QStringLiteral("#ef5350"), QStringLiteral("#ec407a"), QStringLiteral("#ab47bc"), QStringLiteral("#7e57c2"),
        QStringLiteral("#5c6bc0"), QStringLiteral("#42a5f5"), QStringLiteral("#29b6f6"), QStringLiteral("#26c6da"),
        QStringLiteral("#26a69a"), QStringLiteral("#66bb6a"), QStringLiteral("#9ccc65"), QStringLiteral("#d4e157"),
        QStringLiteral("#ffee58"), QStringLiteral("#ffca28"), QStringLiteral("#ffa726"), QStringLiteral("#ff7043"),
        QStringLiteral("#d32f2f"), QStringLiteral("#c2185b"), QStringLiteral("#7b1fa2"), QStringLiteral("#512da8"),
        QStringLiteral("#303f9f"), QStringLiteral("#1976d2"), QStringLiteral("#0288d1"), QStringLiteral("#0097a7"),
        QStringLiteral("#00796b"), QStringLiteral("#388e3c"), QStringLiteral("#689f38"), QStringLiteral("#afb42b"),
        QStringLiteral("#f57f17"), QStringLiteral("#ffffff"), QStringLiteral("#9e9e9e"), QStringLiteral("#000000")
    };
    return colors;
}

QEasingCurve::Type easingFromName(const QString &name)
{
    const QString normalized = name.trimmed().toLower();

    if (normalized == QStringLiteral("linear")) {
        return QEasingCurve::Linear;
    }
    if (normalized == QStringLiteral("out-quad")) {
        return QEasingCurve::OutQuad;
    }
    if (normalized == QStringLiteral("out-quart")) {
        return QEasingCurve::OutQuart;
    }
    if (normalized == QStringLiteral("out-quint")) {
        return QEasingCurve::OutQuint;
    }

    return QEasingCurve::OutCubic;
}

QString runtimeDir()
{
    const QString envRuntime = QString::fromUtf8(qgetenv("XDG_RUNTIME_DIR"));
    if (!envRuntime.trimmed().isEmpty()) {
        return envRuntime;
    }

    const QString runUserPath = QStringLiteral("/run/user/%1").arg(static_cast<qulonglong>(::getuid()));
    if (QFileInfo::exists(runUserPath)) {
        return runUserPath;
    }

    return QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation);
}

QString displayNameForKey(const QString &key)
{
    QString name = key;
    name.remove(QStringLiteral("--color-"));
    name.replace('-', ' ');
    if (!name.isEmpty()) {
        name[0] = name.at(0).toUpper();
    }
    return name;
}

QColor parseColorValue(const QString &value)
{
    const QString trimmed = value.trimmed();
    QColor color(trimmed);
    if (color.isValid()) {
        return color;
    }

    static const QRegularExpression rgbaPattern(
        QStringLiteral(
            R"(^rgba\s*\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})(?:\s*,\s*([0-9]*\.?[0-9]+)\s*)?\)$)"),
        QRegularExpression::CaseInsensitiveOption);
    const QRegularExpressionMatch match = rgbaPattern.match(trimmed);
    if (!match.hasMatch()) {
        return QColor();
    }

    bool okR = false;
    bool okG = false;
    bool okB = false;
    bool okA = true;

    const int r = match.captured(1).toInt(&okR);
    const int g = match.captured(2).toInt(&okG);
    const int b = match.captured(3).toInt(&okB);
    qreal a = 1.0;
    if (!match.captured(4).isEmpty()) {
        a = match.captured(4).toDouble(&okA);
    }
    if (!okR || !okG || !okB || !okA) {
        return QColor();
    }

    QColor parsed(qBound(0, r, 255), qBound(0, g, 255), qBound(0, b, 255));
    parsed.setAlphaF(qBound(0.0, a, 1.0));
    return parsed;
}

bool hasExplicitAlphaComponent(const QString &value)
{
    const QString trimmed = value.trimmed();
    if (trimmed.isEmpty()) {
        return false;
    }

    static const QRegularExpression hexWithAlphaPattern(
        QStringLiteral(R"(^#[0-9A-Fa-f]{8}$)"));
    if (hexWithAlphaPattern.match(trimmed).hasMatch()) {
        return true;
    }

    static const QRegularExpression rgbaPattern(
        QStringLiteral(
            R"(^rgba\s*\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})(?:\s*,\s*([0-9]*\.?[0-9]+)\s*)?\)$)"),
        QRegularExpression::CaseInsensitiveOption);
    const QRegularExpressionMatch rgbaMatch = rgbaPattern.match(trimmed);
    if (!rgbaMatch.hasMatch()) {
        return false;
    }

    return !rgbaMatch.captured(4).isEmpty();
}

QString toHexInputColor(const QColor &color)
{
    if (!color.isValid()) {
        return QStringLiteral("#000000");
    }

    if (color.alpha() >= 255) {
        return color.name(QColor::HexRgb).toLower();
    }

    return color.name(QColor::HexArgb).toLower();
}

QColor parseColorFromPastelOutput(QString output)
{
    static const QRegularExpression ansiSequence(QStringLiteral(R"(\x1B\[[0-9;]*[A-Za-z])"));
    static const QRegularExpression tokenPattern(
        QStringLiteral(R"((#[0-9A-Fa-f]{6,8}|rgba?\([^\)]+\)))"));

    output.remove(ansiSequence);
    QRegularExpressionMatchIterator tokenIt = tokenPattern.globalMatch(output);
    QColor parsed;
    while (tokenIt.hasNext()) {
        const QString token = tokenIt.next().captured(1).trimmed();
        QColor candidate = parseColorValue(token);
        if (candidate.isValid()) {
            parsed = candidate;
        }
    }

    if (parsed.isValid()) {
        return parsed;
    }

    return parseColorValue(output.trimmed());
}

qreal relativeLuminance(const QColor &color)
{
    const auto linearize = [](qreal channel) {
        const qreal normalized = channel / 255.0;
        if (normalized <= 0.03928) {
            return normalized / 12.92;
        }
        return std::pow((normalized + 0.055) / 1.055, 2.4);
    };

    const qreal r = linearize(color.red());
    const qreal g = linearize(color.green());
    const qreal b = linearize(color.blue());
    return (0.2126 * r) + (0.7152 * g) + (0.0722 * b);
}

QColor blendColors(const QColor &left, const QColor &right, qreal amount)
{
    const qreal t = qBound(0.0, amount, 1.0);
    const qreal inv = 1.0 - t;
    return QColor(
        qRound((left.red() * inv) + (right.red() * t)),
        qRound((left.green() * inv) + (right.green() * t)),
        qRound((left.blue() * inv) + (right.blue() * t)),
        qRound((left.alpha() * inv) + (right.alpha() * t)));
}

QColor hsvColor(qreal hue, qreal saturation, qreal value)
{
    const qreal wrappedHue = hue - std::floor(hue);
    return QColor::fromHsvF(
        wrappedHue,
        qBound(0.0, saturation, 1.0),
        qBound(0.0, value, 1.0));
}

QList<QColor> buildTerminal24FromBase(const QColor &base)
{
    float hue = 0.0f;
    float saturation = 0.0f;
    float value = 0.0f;
    base.getHsvF(&hue, &saturation, &value);
    if (hue < 0.0) {
        hue = 0.0;
    }

    const qreal neutralSaturation = qBound(0.0, saturation * 0.12, 0.14);
    const qreal normalSaturation = qBound(0.42, 0.36 + (saturation * 0.42), 0.82);
    const qreal normalValue = qBound(0.38, 0.40 + (value * 0.25), 0.72);
    const qreal brightSaturation = qBound(0.48, normalSaturation + 0.08, 0.90);
    const qreal brightValue = qBound(0.64, normalValue + 0.22, 0.96);

    QList<QColor> colors;
    colors.reserve(24);

    const QColor normalBlack = hsvColor(hue, neutralSaturation, qBound(0.06, value * 0.18, 0.20));
    const QColor normalWhite = hsvColor(hue, qBound(0.0, saturation * 0.06, 0.08), qBound(0.72, value * 0.75 + 0.16, 0.90));
    const QColor brightBlack = hsvColor(hue, neutralSaturation, qBound(0.20, value * 0.34 + 0.06, 0.40));
    const QColor brightWhite = hsvColor(hue, qBound(0.0, saturation * 0.04, 0.06), qBound(0.92, value * 0.92 + 0.18, 1.0));

    colors << normalBlack;
    colors << hsvColor(hue + (0.0 / 360.0), normalSaturation, normalValue);
    colors << hsvColor(hue + (120.0 / 360.0), normalSaturation, normalValue);
    colors << hsvColor(hue + (60.0 / 360.0), normalSaturation, normalValue);
    colors << hsvColor(hue + (240.0 / 360.0), normalSaturation, normalValue);
    colors << hsvColor(hue + (300.0 / 360.0), normalSaturation, normalValue);
    colors << hsvColor(hue + (180.0 / 360.0), normalSaturation, normalValue);
    colors << normalWhite;

    colors << brightBlack;
    colors << hsvColor(hue + (0.0 / 360.0), brightSaturation, brightValue);
    colors << hsvColor(hue + (120.0 / 360.0), brightSaturation, brightValue);
    colors << hsvColor(hue + (60.0 / 360.0), brightSaturation, brightValue);
    colors << hsvColor(hue + (240.0 / 360.0), brightSaturation, brightValue);
    colors << hsvColor(hue + (300.0 / 360.0), brightSaturation, brightValue);
    colors << hsvColor(hue + (180.0 / 360.0), brightSaturation, brightValue);
    colors << brightWhite;

    const QColor dimAnchor = blendColors(normalBlack, base, 0.10);
    for (int i = 0; i < 8; ++i) {
        const QColor dim = blendColors(colors.at(i), dimAnchor, 0.46);
        colors << hsvColor(
            dim.hsvHueF() < 0.0 ? hue : dim.hsvHueF(),
            qBound(0.0, dim.hsvSaturationF() * 0.72, 1.0),
            qBound(0.0, dim.valueF() * 0.80, 1.0));
    }

    return colors;
}

QStringList terminalPaletteRowNames()
{
    QStringList names = {
        QStringLiteral("Foreground"),
        QStringLiteral("Background")
    };
    for (int i = 0; i < 24; ++i) {
        names << QStringLiteral("Color %1").arg(i, 2, 10, QLatin1Char('0'));
    }
    return names;
}

QString toCssColor(const QColor &color)
{
    if (!color.isValid()) {
        return QStringLiteral("#000000");
    }

    if (color.alpha() >= 255) {
        return color.name(QColor::HexRgb).toLower();
    }

    QString alpha = QString::number(color.alphaF(), 'f', 2);
    while (alpha.endsWith('0')) {
        alpha.chop(1);
    }
    if (alpha.endsWith('.')) {
        alpha.chop(1);
    }

    return QStringLiteral("rgba(%1, %2, %3, %4)")
        .arg(color.red())
        .arg(color.green())
        .arg(color.blue())
        .arg(alpha);
}

QString toPaletteFileColor(const QColor &color)
{
    if (!color.isValid()) {
        return QStringLiteral("#000000");
    }

    QString value = QStringLiteral("#%1%2%3")
        .arg(color.red(), 2, 16, QLatin1Char('0'))
        .arg(color.green(), 2, 16, QLatin1Char('0'))
        .arg(color.blue(), 2, 16, QLatin1Char('0'));

    if (color.alpha() < 255) {
        value += QStringLiteral("%1").arg(color.alpha(), 2, 16, QLatin1Char('0'));
    }

    return value.toLower();
}

QString toRgbaColor(const QColor &color)
{
    if (!color.isValid()) {
        return QStringLiteral("rgba(0, 0, 0, 1)");
    }

    QString alpha = QString::number(color.alphaF(), 'f', 2);
    while (alpha.endsWith('0')) {
        alpha.chop(1);
    }
    if (alpha.endsWith('.')) {
        alpha.chop(1);
    }

    return QStringLiteral("rgba(%1, %2, %3, %4)")
        .arg(color.red())
        .arg(color.green())
        .arg(color.blue())
        .arg(alpha);
}

QList<QColor> buildShadeScale(const QColor &base, int steps)
{
    QList<QColor> colors;
    if (!base.isValid() || steps <= 0) {
        return colors;
    }

    colors.reserve(steps);
    const QColor black(0, 0, 0, base.alpha());
    const int divisor = qMax(1, steps - 1);
    for (int i = 0; i < steps; ++i) {
        const qreal amount = static_cast<qreal>(i) / static_cast<qreal>(divisor);
        colors << blendColors(black, base, amount);
    }
    return colors;
}

QList<QColor> buildTintScale(const QColor &base, int steps)
{
    QList<QColor> colors;
    if (!base.isValid() || steps <= 0) {
        return colors;
    }

    colors.reserve(steps);
    const QColor white(255, 255, 255, base.alpha());
    const int divisor = qMax(1, steps - 1);
    for (int i = 0; i < steps; ++i) {
        const qreal amount = static_cast<qreal>(i) / static_cast<qreal>(divisor);
        colors << blendColors(base, white, amount);
    }
    return colors;
}

QList<QColor> buildToneScale(const QColor &base, int steps)
{
    QList<QColor> colors;
    if (!base.isValid() || steps <= 0) {
        return colors;
    }

    float hue = 0.0f;
    float saturation = 0.0f;
    float value = 0.0f;
    float alpha = 1.0f;
    base.getHsvF(&hue, &saturation, &value, &alpha);
    if (hue < 0.0) {
        hue = 0.0;
    }

    const qreal minSaturation = qBound(0.0, saturation * 0.12, 0.28);
    const qreal maxSaturation = qBound(0.0, saturation + 0.28, 1.0);
    const int divisor = qMax(1, steps - 1);

    colors.reserve(steps);
    for (int i = 0; i < steps; ++i) {
        const qreal amount = static_cast<qreal>(i) / static_cast<qreal>(divisor);
        const qreal sat = minSaturation + ((maxSaturation - minSaturation) * amount);
        const qreal toneValue = qBound(0.0, (value * 0.92) + (0.08 * amount), 1.0);
        colors << QColor::fromHsvF(hue, sat, toneValue, alpha);
    }

    return colors;
}

qreal wrapHueDegrees(qreal hue)
{
    const qreal wrapped = std::fmod(hue, 360.0);
    return wrapped < 0.0 ? wrapped + 360.0 : wrapped;
}

QColor colorAtHue(const QColor &base, qreal hueDegrees, qreal saturationScale = 1.0, qreal valueScale = 1.0)
{
    float hue = 0.0f;
    float saturation = 0.0f;
    float value = 0.0f;
    float alpha = 1.0f;
    base.getHsvF(&hue, &saturation, &value, &alpha);
    if (hue < 0.0f) {
        hue = 0.0f;
    }

    const qreal normalizedHue = wrapHueDegrees(hueDegrees) / 360.0;
    const qreal nextSaturation = qBound(0.0, saturation * saturationScale, 1.0);
    const qreal nextValue = qBound(0.0, value * valueScale, 1.0);
    return QColor::fromHsvF(normalizedHue, nextSaturation, nextValue, alpha);
}

QList<QColor> complementaryTheory(const QColor &base)
{
    const qreal baseHue = wrapHueDegrees(base.hsvHueF() < 0.0 ? 0.0 : base.hsvHueF() * 360.0);
    return {colorAtHue(base, baseHue), colorAtHue(base, baseHue + 180.0)};
}

QList<QColor> analogousTheory(const QColor &base)
{
    const qreal baseHue = wrapHueDegrees(base.hsvHueF() < 0.0 ? 0.0 : base.hsvHueF() * 360.0);
    return {colorAtHue(base, baseHue - 30.0), colorAtHue(base, baseHue), colorAtHue(base, baseHue + 30.0)};
}

QList<QColor> splitComplementaryTheory(const QColor &base)
{
    const qreal baseHue = wrapHueDegrees(base.hsvHueF() < 0.0 ? 0.0 : base.hsvHueF() * 360.0);
    return {colorAtHue(base, baseHue), colorAtHue(base, baseHue + 150.0), colorAtHue(base, baseHue + 210.0)};
}

QList<QColor> triadicTheory(const QColor &base)
{
    const qreal baseHue = wrapHueDegrees(base.hsvHueF() < 0.0 ? 0.0 : base.hsvHueF() * 360.0);
    return {colorAtHue(base, baseHue), colorAtHue(base, baseHue + 120.0), colorAtHue(base, baseHue + 240.0)};
}

QList<QColor> tetradicTheory(const QColor &base)
{
    const qreal baseHue = wrapHueDegrees(base.hsvHueF() < 0.0 ? 0.0 : base.hsvHueF() * 360.0);
    return {
        colorAtHue(base, baseHue),
        colorAtHue(base, baseHue + 90.0),
        colorAtHue(base, baseHue + 180.0),
        colorAtHue(base, baseHue + 270.0)
    };
}

QList<QColor> monochromaticTheory(const QColor &base)
{
    QList<QColor> result;
    result.reserve(7);

    float baseHue = 0.0f;
    float baseSaturation = 0.0f;
    float baseValue = 0.0f;
    float alpha = 1.0f;
    base.getHsvF(&baseHue, &baseSaturation, &baseValue, &alpha);
    if (baseHue < 0.0f) {
        baseHue = 0.0f;
    }

    const QList<qreal> valueSteps = {0.40, 0.52, 0.64, 0.76, 0.84, 0.92, 1.0};
    const QList<qreal> saturationSteps = {1.10, 1.06, 1.02, 0.98, 0.90, 0.82, 0.74};
    for (int i = 0; i < valueSteps.size(); ++i) {
        const qreal adjustedValue = qBound(0.0, baseValue * valueSteps.at(i), 1.0);
        const qreal adjustedSaturation = qBound(0.0, baseSaturation * saturationSteps.at(i), 1.0);
        result.append(QColor::fromHsvF(baseHue, adjustedSaturation, adjustedValue, alpha));
    }

    return result;
}

QList<QColor> theoryWheelColors(const QColor &base)
{
    QList<QColor> colors;
    colors.reserve(24);
    const qreal baseHue = wrapHueDegrees(base.hsvHueF() < 0.0 ? 0.0 : base.hsvHueF() * 360.0);
    constexpr int kWheelSegments = 24;
    constexpr qreal kStep = 360.0 / kWheelSegments;
    for (int i = 0; i < kWheelSegments; ++i) {
        colors.append(colorAtHue(base, baseHue + (kStep * i)));
    }
    return colors;
}

bool isMaterialColorKey(const QString &key)
{
    return key.startsWith(QStringLiteral("--color-material-"));
}

QList<QPair<QString, QString>> extractVariables(const QString &text)
{
    QList<QPair<QString, QString>> variables;
    static const QRegularExpression pattern(
        QStringLiteral(R"((--[A-Za-z0-9_-]+)\s*:\s*([^;{}]+);)"));

    QHash<QString, QString> valuesByKey;
    QStringList keyOrder;
    QRegularExpressionMatchIterator it = pattern.globalMatch(text);
    while (it.hasNext()) {
        const QRegularExpressionMatch match = it.next();
        const QString key = match.captured(1).trimmed();
        if (!valuesByKey.contains(key)) {
            keyOrder.append(key);
        }
        valuesByKey.insert(key, match.captured(2).trimmed());
    }

    for (const QString &key : keyOrder) {
        variables.append({key, valuesByKey.value(key)});
    }

    return variables;
}

QString sanitizePaletteFileBase(QString name)
{
    name = name.trimmed().toLower();
    name.replace(QRegularExpression(QStringLiteral(R"([^a-z0-9._-]+)")), QStringLiteral("-"));
    name.replace(QRegularExpression(QStringLiteral(R"(-{2,})")), QStringLiteral("-"));
    name.remove(QRegularExpression(QStringLiteral(R"(^[.-]+|[.-]+$)")));

    if (name.isEmpty()) {
        return QStringLiteral("palette");
    }

    return name;
}

QString tomlQuoted(QString value)
{
    value.replace(QLatin1Char('\\'), QStringLiteral("\\\\"));
    value.replace(QLatin1Char('"'), QStringLiteral("\\\""));
    value.replace(QLatin1Char('\n'), QStringLiteral("\\n"));
    value.replace(QLatin1Char('\r'), QStringLiteral("\\r"));
    return QStringLiteral("\"%1\"").arg(value);
}

QString paletteColorKey(const QString &label)
{
    QString key = label.trimmed().toLower();
    key.replace(QRegularExpression(QStringLiteral(R"([^a-z0-9]+)")), QStringLiteral("_"));
    key.remove(QRegularExpression(QStringLiteral(R"(^_+|_+$)")));
    return key.isEmpty() ? QStringLiteral("color") : key;
}

QString displayPathWithTilde(const QString &path)
{
    const QString homePath = QDir::homePath();
    if (path == homePath) {
        return QStringLiteral("~");
    }
    if (path.startsWith(homePath + QLatin1Char('/'))) {
        return QStringLiteral("~") + path.mid(homePath.size());
    }
    return path;
}


}
