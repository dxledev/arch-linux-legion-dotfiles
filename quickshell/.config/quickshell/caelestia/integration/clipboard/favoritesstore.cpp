#include "favoritesstore.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>
#include <QStandardPaths>
#include <QRegularExpression>

namespace {
QFileDevice::Permissions ownerFilePermissions()
{
    return QFileDevice::ReadOwner | QFileDevice::WriteOwner;
}
}

FavoritesStore::FavoritesStore(QObject *parent)
    : QObject(parent)
{
    const QString dataHome = qEnvironmentVariable("XDG_DATA_HOME").isEmpty()
        ? QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/.local/share"
        : qEnvironmentVariable("XDG_DATA_HOME");
    m_directory = QDir(dataHome).filePath("caelestia/clipboard");
}

void FavoritesStore::setDirectory(QString directory)
{
    if (!directory.isEmpty())
        m_directory = std::move(directory);
}

QString FavoritesStore::directory() const
{
    return m_directory;
}

bool FavoritesStore::validHash(const QString &hash) const
{
    static const QRegularExpression expression(QStringLiteral("^[0-9a-f]{64}$"));
    return expression.match(hash).hasMatch();
}

bool FavoritesStore::ensureDirectory(QString *errorText) const
{
    QDir directory(m_directory);
    if (!directory.exists() && !directory.mkpath(".")) {
        if (errorText) *errorText = "Could not create clipboard favorites storage.";
        return false;
    }
    if (!QFile::setPermissions(m_directory, QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner)) {
        if (errorText) *errorText = "Could not set private permissions on clipboard favorites storage.";
        return false;
    }
    return true;
}

bool FavoritesStore::load(QString *errorText)
{
    if (!ensureDirectory(errorText)) {
        m_healthy = false;
        return false;
    }

    const QString manifestPath = QDir(m_directory).filePath("favorites.json");
    QFile manifest(manifestPath);
    if (!manifest.exists()) {
        m_hashes.clear();
        m_healthy = true;
        return true;
    }
    if (!manifest.open(QIODevice::ReadOnly)) {
        if (errorText) *errorText = manifest.errorString();
        m_healthy = false;
        return false;
    }

    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(manifest.readAll(), &parseError);
    const QJsonObject object = document.object();
    if (parseError.error != QJsonParseError::NoError || !document.isObject()
        || object.value("version").toInt(-1) != 1 || !object.value("items").isArray()) {
        if (errorText) *errorText = "Clipboard favorites manifest is corrupt or unsupported.";
        m_healthy = false;
        return false;
    }

    QStringList loaded;
    for (const auto &value : object.value("items").toArray()) {
        const QString hash = value.toString();
        if (!validHash(hash) || loaded.contains(hash)) {
            if (errorText) *errorText = "Clipboard favorites manifest contains an invalid entry.";
            m_healthy = false;
            return false;
        }
        QFile payload(payloadPath(hash));
        if (!payload.open(QIODevice::ReadOnly)) {
            if (errorText) *errorText = "A saved clipboard favorite payload is missing or unreadable.";
            m_healthy = false;
            return false;
        }
        loaded.append(hash);
    }
    m_hashes = loaded;
    m_healthy = true;
    return true;
}

QStringList FavoritesStore::hashes() const
{
    return m_hashes;
}

QString FavoritesStore::payloadPath(const QString &hash) const
{
    return QDir(m_directory).filePath(hash + ".payload");
}

bool FavoritesStore::writeManifest(const QStringList &hashes, QString *errorText) const
{
    if (!ensureDirectory(errorText))
        return false;
    QJsonArray items;
    for (const auto &hash : hashes)
        items.append(hash);
    QJsonObject object{{"version", 1}, {"items", items}};
    QSaveFile file(QDir(m_directory).filePath("favorites.json"));
    file.setDirectWriteFallback(false);
    if (!file.open(QIODevice::WriteOnly)) {
        if (errorText) *errorText = file.errorString();
        return false;
    }
    if (!file.setPermissions(ownerFilePermissions())) {
        file.cancelWriting();
        if (errorText) *errorText = "Could not set private permissions on the favorites manifest.";
        return false;
    }
    if (file.write(QJsonDocument(object).toJson(QJsonDocument::Indented)) < 0 || !file.commit()) {
        if (errorText) *errorText = file.errorString();
        return false;
    }
    return true;
}

bool FavoritesStore::add(const QString &hash, const QString &sourcePath, QString *errorText)
{
    if (!m_healthy || !validHash(hash)) {
        if (errorText) *errorText = "Clipboard favorites storage is unavailable.";
        return false;
    }
    if (m_hashes.contains(hash))
        return true;
    if (!ensureDirectory(errorText))
        return false;

    QFile source(sourcePath);
    if (!source.open(QIODevice::ReadOnly)) {
        if (errorText) *errorText = source.errorString();
        return false;
    }
    QSaveFile payload(payloadPath(hash));
    payload.setDirectWriteFallback(false);
    if (!payload.open(QIODevice::WriteOnly)) {
        if (errorText) *errorText = payload.errorString();
        return false;
    }
    if (!payload.setPermissions(ownerFilePermissions())) {
        payload.cancelWriting();
        if (errorText) *errorText = "Could not set private permissions on the favorite payload.";
        return false;
    }
    while (!source.atEnd()) {
        const QByteArray chunk = source.read(1024 * 1024);
        if (chunk.isEmpty() && source.error() != QFileDevice::NoError) {
            payload.cancelWriting();
            if (errorText) *errorText = source.errorString();
            return false;
        }
        if (payload.write(chunk) != chunk.size()) {
            payload.cancelWriting();
            if (errorText) *errorText = payload.errorString();
            return false;
        }
    }
    if (!payload.commit()) {
        if (errorText) *errorText = payload.errorString();
        return false;
    }

    QStringList next = m_hashes;
    next.append(hash);
    if (!writeManifest(next, errorText))
        return false;
    m_hashes = next;
    emit changed();
    return true;
}

bool FavoritesStore::remove(const QString &hash, QString *errorText)
{
    if (!m_healthy || !m_hashes.contains(hash))
        return false;
    QStringList next = m_hashes;
    next.removeAll(hash);
    if (!writeManifest(next, errorText))
        return false;
    m_hashes = next;
    QFile::remove(payloadPath(hash));
    emit changed();
    return true;
}

bool FavoritesStore::clear(QString *errorText)
{
    if (!m_healthy) {
        if (errorText) *errorText = "Clipboard favorites storage is unavailable.";
        return false;
    }
    const QStringList payloadFiles = QDir(m_directory).entryList({"*.payload"}, QDir::Files);
    if (!writeManifest({}, errorText))
        return false;
    m_hashes.clear();
    emit changed();

    for (const auto &fileName : payloadFiles) {
        const QString path = QDir(m_directory).filePath(fileName);
        if (QFileInfo::exists(path) && !QFile::remove(path))
            emit error("Favorites were cleared, but a saved payload could not be removed.");
    }
    return true;
}

bool FavoritesStore::moveBefore(const QString &hash, const QString &beforeHash, QString *errorText)
{
    if (!m_healthy || !m_hashes.contains(hash))
        return false;
    if (hash == beforeHash)
        return true;
    if (!beforeHash.isEmpty() && !m_hashes.contains(beforeHash)) {
        if (errorText) *errorText = "The destination favorite no longer exists.";
        return false;
    }
    QStringList next = m_hashes;
    next.removeAll(hash);
    const qsizetype insertion = beforeHash.isEmpty() ? next.size() : next.indexOf(beforeHash);
    if (insertion < 0) {
        if (errorText) *errorText = "The destination favorite no longer exists.";
        return false;
    }
    next.insert(insertion, hash);
    if (next == m_hashes)
        return true;
    if (!writeManifest(next, errorText))
        return false;
    m_hashes = next;
    emit changed();
    return true;
}
