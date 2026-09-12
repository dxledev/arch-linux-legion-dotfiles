#include "chromack-model.h"
#include "color-functions.h"
#include <QClipboard>
#include <QGuiApplication>
#include <QImage>
#include <QProcess>
#include <QProcessEnvironment>
#include <QSaveFile>
#include <QTextStream>
#include <algorithm>
using namespace ChromackColors;

ChromackModel::ChromackModel(QObject *parent) : QObject(parent), loader_(this)
{
    connect(&loader_, &ChromackConfigLoader::styleChanged, this, &ChromackModel::loadStyle);
    cacheTimer_.setSingleShot(true);
    cacheTimer_.setInterval(120);
    connect(&cacheTimer_, &QTimer::timeout, this, &ChromackModel::writeCache);
    loadStyle();
    loadCaches();
}

QString ChromackModel::expandPath(QString path) const
{
    if (path.startsWith("~/")) path.replace(0, 1, QDir::homePath());
    const auto environment = QProcessEnvironment::systemEnvironment();
    for (const auto &key : environment.keys()) {
        path.replace("${" + key + "}", environment.value(key));
        path.replace("$" + key, environment.value(key));
    }
    return path;
}

QColor ChromackModel::active() const { return parseColorValue(variables_.value(activeKey_)); }
QColor ChromackModel::parse(const QString &value) const { return parseColorValue(value); }
void ChromackModel::reload() { loader_.reload(); }

void ChromackModel::loadStyle()
{
    const QColor previous = active();
    variables_ = loader_.styleVariables();
    materialKeys_.clear();
    for (int i = 0; i < materialPaletteColors().size(); ++i) {
        const QString key = materialPaletteKey(i);
        materialKeys_.append(key);
        if (!variables_.contains(key)) variables_.insert(key, materialPaletteColors().at(i));
    }
    if (!materialKeys_.contains(activeKey_)) activeKey_ = materialKeys_.first();
    if (previous.isValid()) variables_[activeKey_] = toCssColor(previous);
    hue_ = qMax(0, active().hsvHue());
    emit changed();
}

QString ChromackModel::resolvedStyle(const QString &key) const
{
    QString value = variables_.value(key);
    const QRegularExpression pattern(R"(var\((--[\w-]+)\))");
    for (int i = 0; i < 20; ++i) {
        const auto match = pattern.match(value);
        if (!match.hasMatch()) break;
        value.replace(match.captured(), variables_.value(match.captured(1)));
    }
    if (value.startsWith('"') && value.endsWith('"')) value = value.mid(1, value.size() - 2);
    return value;
}

QVariantList ChromackModel::colorList(const QList<QColor> &colors) const
{
    QVariantList result;
    for (const auto &color : colors)
        result.append(QVariantMap{{"color", color}, {"css", toCssColor(color)}, {"hex", color.name()}});
    return result;
}

QVariantList ChromackModel::palette() const
{
    const auto base = active();
    const auto terminal = buildTerminal24FromBase(base);
    const auto background = blendColors(terminal.first(), base, 0.20);
    const auto foreground = relativeLuminance(background) > 0.42
        ? blendColors(terminal.first(), base, 0.18) : blendColors(terminal.at(15), base, 0.08);
    QList<QColor> colors{foreground, background};
    colors.append(terminal);
    auto result = colorList(colors);
    const auto names = terminalPaletteRowNames();
    for (int i = 0; i < result.size(); ++i) {
        auto row = result[i].toMap();
        row["name"] = names[i];
        result[i] = row;
    }
    return result;
}

QVariantMap ChromackModel::state() const
{
    const auto color = active();
    QVariantMap style;
    for (auto it = variables_.cbegin(); it != variables_.cend(); ++it) style[it.key().mid(2)] = resolvedStyle(it.key());
    QList<QColor> materials;
    for (const auto &key : materialKeys_) materials.append(parseColorValue(variables_.value(key)));
    const QList<QList<QColor>> scales{buildShadeScale(color, 12), buildTintScale(color, 12), buildToneScale(color, 12)};
    const QStringList shadeNames{"Shades", "Tints", "Tones"};
    const QStringList descriptions{"%1 is darkest while %2 is closest to base.", "%1 starts at base and %2 is lightest.", "%1 is least saturated while %2 is most saturated."};
    QVariantList shades;
    for (int i = 0; i < scales.size(); ++i)
        shades.append(QVariantMap{{"name", shadeNames[i]}, {"colors", colorList(scales[i])}, {"description", descriptions[i].arg(scales[i].first().name(), scales[i].last().name())}});
    const QList<QList<QColor>> schemes{complementaryTheory(color), analogousTheory(color), splitComplementaryTheory(color), triadicTheory(color), tetradicTheory(color), monochromaticTheory(color)};
    const QStringList names{"Complementary Color", "Analogous Color", "Split Complementary Color", "Triadic Color", "Tetradic Color", "Monochromatic Color"};
    QVariantList theory;
    for (int i = 0; i < schemes.size(); ++i) theory.append(QVariantMap{{"name", names[i]}, {"colors", colorList(schemes[i])}});
    return {{"color", color}, {"hex", toHexInputColor(color)}, {"rgba", toRgbaColor(color)}, {"css", toCssColor(color)},
        {"key", activeKey_}, {"subtitle", displayNameForKey(activeKey_) + " · " + toCssColor(color)},
        {"hue", hue_}, {"saturation", color.hsvSaturationF()}, {"value", color.valueF()}, {"alpha", color.alpha()},
        {"materials", colorList(materials)}, {"selected", materialKeys_.indexOf(activeKey_)}, {"recent", colorList(recent_)},
        {"palette", palette()}, {"shades", shades}, {"theory", theory}, {"wheel", colorList(theoryWheelColors(color))},
        {"style", style}, {"status", status_}, {"title", loader_.config().panel.title}, {"scrollbar", loader_.config().panel.scrollbar}};
}

void ChromackModel::selectMaterial(int index)
{
    if (index < 0 || index >= materialKeys_.size()) return;
    activeKey_ = materialKeys_[index];
    hue_ = qMax(0, active().hsvHue());
    cacheTimer_.start();
    emit changed();
}

bool ChromackModel::setColor(const QString &value, bool recent, bool preserveAlpha)
{
    auto color = parseColorValue(value);
    if (!color.isValid()) return false;
    if (preserveAlpha && !hasExplicitAlphaComponent(value)) color.setAlpha(active().alpha());
    updateColor(color, recent);
    return true;
}

void ChromackModel::updateColor(const QColor &color, bool recent)
{
    variables_[activeKey_] = toCssColor(color);
    if (color.hsvHue() >= 0) hue_ = color.hsvHue();
    if (recent) pushRecent(color);
    cacheTimer_.start();
    emit changed();
}

void ChromackModel::setHsv(int hue, double saturation, double value, int alpha)
{
    hue_ = qBound(0, hue, 359);
    updateColor(QColor::fromHsv(hue_, qRound(qBound(0.0, saturation, 1.0) * 255), qRound(qBound(0.0, value, 1.0) * 255), qBound(0, alpha, 255)), false);
}

void ChromackModel::setAlpha(int alpha)
{
    QColor color = active();
    color.setAlpha(qBound(0, alpha, 255));
    updateColor(color, false);
}

bool ChromackModel::generate(const QString &value)
{
    if (!setColor(value, false, true)) {
        status_ = "Invalid color. Use hex or rgba.";
        emit changed();
        return false;
    }
    status_ = "Generated 24-base palette from " + toCssColor(active());
    emit changed();
    return true;
}

void ChromackModel::pushRecent(const QColor &color)
{
    recent_.removeIf([&](const QColor &existing) { return existing.rgba() == color.rgba(); });
    recent_.prepend(color);
    while (recent_.size() > 16) recent_.removeLast();
    QByteArray data;
    for (const auto &entry : recent_) data += toCssColor(entry).toUtf8() + '\n';
    writeFile(loader_.config().paths.recentColorsFile, data);
}

void ChromackModel::copy(const QString &value)
{
    if (value.isEmpty()) return;
    auto *process = new QProcess(this);
    connect(process, &QProcess::started, this, [process, value] {
        process->write(value.toUtf8());
        process->closeWriteChannel();
    });
    connect(process, &QProcess::errorOccurred, this, [process, value] {
        QGuiApplication::clipboard()->setText(value);
        process->deleteLater();
    });
    connect(process, &QProcess::finished, process, &QObject::deleteLater);
    process->start("/usr/bin/wl-copy");
    const auto color = parseColorValue(value);
    if (color.isValid()) { pushRecent(color); emit changed(); }
    notifyColor(value, color);
}

void ChromackModel::notifyColor(const QString &value, const QColor &color)
{
    QStringList args{"-p", "-a", "Chromack", "-t", "5000"};
    if (notificationAge_.isValid() && notificationAge_.elapsed() < 5000 && !notificationId_.isEmpty())
        args << "-r" << notificationId_;
    const QString directory = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation) + "/quickshell-chromack";
    if (color.isValid() && QDir().mkpath(directory)) {
        QImage image(32, 32, QImage::Format_ARGB32);
        image.fill(color);
        const auto path = directory + "/colorpick.png";
        if (image.save(path)) args << "-i" << path;
    }
    args << "Color Picker" << value;
    auto *process = new QProcess(this);
    connect(process, &QProcess::finished, this, [this, process](int code) {
        const auto id = QString::fromUtf8(process->readAllStandardOutput()).trimmed();
        if (code == 0 && QRegularExpression("^[0-9]+$").match(id).hasMatch()) {
            notificationId_ = id;
            notificationAge_.start();
        }
        process->deleteLater();
    });
    connect(process, &QProcess::errorOccurred, process, &QObject::deleteLater);
    const QString wrapper = QDir::homePath() + "/bin/notify-send";
    process->start(QFileInfo(wrapper).isExecutable() ? wrapper : "/usr/bin/notify-send", args);
}

bool ChromackModel::writeFile(const QString &path, const QByteArray &data)
{
    const auto expanded = expandPath(path);
    const QFileInfo info(expanded);
    if (!QDir().mkpath(info.absolutePath())) { emit error("Could not create " + info.absolutePath()); return false; }
    QSaveFile file(info.exists() ? info.canonicalFilePath() : expanded);
    if (!file.open(QIODevice::WriteOnly) || file.write(data) != data.size() || !file.commit()) {
        emit error("Could not save " + expanded);
        return false;
    }
    return true;
}

void ChromackModel::loadCaches()
{
    QFile recentFile(expandPath(loader_.config().paths.recentColorsFile));
    if (recentFile.open(QIODevice::ReadOnly)) {
        while (!recentFile.atEnd() && recent_.size() < 16) {
            const auto color = parseColorValue(QString::fromUtf8(recentFile.readLine()).trimmed());
            if (color.isValid() && !recent_.contains(color)) recent_.append(color);
        }
    }
    QFile activeFile(expandPath(loader_.config().paths.activeColorFile));
    if (activeFile.open(QIODevice::ReadOnly)) {
        const auto key = QString::fromUtf8(activeFile.readLine()).trimmed();
        const auto color = parseColorValue(QString::fromUtf8(activeFile.readLine()).trimmed());
        if (materialKeys_.contains(key)) activeKey_ = key;
        if (color.isValid()) variables_[activeKey_] = toCssColor(color);
    }
    hue_ = qMax(0, active().hsvHue());
    emit changed();
}

bool ChromackModel::writeCache()
{
    return writeFile(loader_.config().paths.activeColorFile, (activeKey_ + '\n' + toCssColor(active()) + '\n').toUtf8());
}

bool ChromackModel::writeCss(const QString &path, bool material, bool combined)
{
    QFile file(expandPath(path));
    const bool readable = file.open(QIODevice::ReadOnly);
    if (file.exists() && !readable) { emit error("Could not read " + path); return false; }
    const auto entries = extractVariables(readable ? QString::fromUtf8(file.readAll()) : QString());
    file.close();
    QStringList keys;
    QHash<QString, QString> values;
    for (const auto &entry : entries) {
        if (combined || !entry.first.startsWith("--color-") || isMaterialColorKey(entry.first) == material) {
            keys.append(entry.first);
            values[entry.first] = entry.second;
        }
    }
    if (material || combined) for (const auto &key : materialKeys_) {
        if (!keys.contains(key)) keys.append(key);
        values[key] = toCssColor(parseColorValue(variables_.value(key)));
    }
    QByteArray data(":root {\n");
    for (const auto &key : keys) data += "    " + key.toUtf8() + ": " + values[key].toUtf8() + ";\n";
    return writeFile(path, data + "}\n");
}

bool ChromackModel::flush()
{
    cacheTimer_.stop();
    const auto paths = loader_.config().paths;
    const bool combined = expandPath(paths.colorsCss) == expandPath(paths.materialCss);
    const bool cache = writeCache();
    const bool colors = writeCss(paths.colorsCss, false, combined);
    const bool materials = combined || writeCss(paths.materialCss, true, false);
    return cache && colors && materials;
}

QString ChromackModel::savePalette(const QString &name)
{
    const QString title = name.trimmed().isEmpty() ? "Palette" : name.trimmed();
    const QString base = sanitizePaletteFileBase(title);
    QDir dir(expandPath(loader_.config().paths.paletteDirectory));
    if (!QDir().mkpath(dir.path())) { emit error("Could not create palette directory."); return {}; }
    QString path;
    QFile file;
    for (int suffix = 1; ; ++suffix) {
        path = dir.filePath(base + (suffix == 1 ? QString() : "-" + QString::number(suffix)) + ".toml");
        file.setFileName(path);
        if (file.open(QIODevice::WriteOnly | QIODevice::NewOnly)) break;
        if (!QFileInfo::exists(path)) { emit error("Could not save palette."); return {}; }
    }
    QByteArray data = ("[palette]\nname = " + tomlQuoted(title) + "\nbase = " + tomlQuoted(toPaletteFileColor(active())) + "\n\n[colors]\n").toUtf8();
    for (const auto &entry : palette()) {
        const auto row = entry.toMap();
        data += (paletteColorKey(row["name"].toString()) + " = " + tomlQuoted(toPaletteFileColor(row["color"].value<QColor>())) + '\n').toUtf8();
    }
    if (file.write(data) != data.size() || !file.flush()) { emit error("Could not save palette."); return {}; }
    status_ = "Saved palette to " + path;
    emit changed();
    QProcess::startDetached("/usr/bin/notify-send", {"-a", "Chromack", "-t", "5000", "Chromack", "Palette saved to " + displayPathWithTilde(path)});
    return path;
}
