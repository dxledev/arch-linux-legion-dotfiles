#include "clipboardcontroller.h"

#include "payloadclassifier.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFutureWatcher>
#include <QStandardPaths>
#include <QTimer>
#include <QUrl>
#include <QtConcurrent/QtConcurrentRun>

ClipboardController::ClipboardController(QObject *parent)
    : QObject(parent), m_historyModel(false), m_favoritesModel(true), m_backend(), m_store()
{
    const QString cacheHome = qEnvironmentVariable("XDG_CACHE_HOME").isEmpty()
        ? QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/.cache"
        : qEnvironmentVariable("XDG_CACHE_HOME");
    m_thumbnailDirectory = QDir(cacheHome).filePath("caelestia/clipboard/thumbnails");
    connect(&m_backend, &CliphistBackend::listingReady, this, &ClipboardController::acceptListing);
    connect(&m_backend, &CliphistBackend::wipeFinished, this,
            [this](quint64 request, bool success, const QString &message) {
        if (request != m_historyClearRequest)
            return;
        m_clearingHistory = false;
        emit clearingHistoryChanged();
        if (!success) {
            setError(message);
            emit historyClearCompleted(false, message);
            return;
        }
        setError({});
        if (m_refreshInFlight) {
            m_refreshQueued = true;
            m_discardListingAfterHistoryClear = true;
        } else {
            refresh();
        }
        emit historyClearCompleted(true, {});
    });
    connect(&m_backend, &CliphistBackend::decodeReady, this, &ClipboardController::acceptDecoded);
    connect(&m_backend, &CliphistBackend::copyFinished, this,
            [this](const QString &key, quint64 request, bool success, const QString &message) {
        if (request != m_copyRequest)
            return;
        if (!success)
            setError(message);
        else
            setError({});
        emit copyCompleted(key, success, message);
    });
    connect(&m_backend, &CliphistBackend::error, this, &ClipboardController::setError);
    connect(&m_store, &FavoritesStore::changed, this, &ClipboardController::rebuildFavorites);
    connect(&m_store, &FavoritesStore::error, this, &ClipboardController::setError);
}

QAbstractItemModel *ClipboardController::historyModel() const { return const_cast<ClipboardListModel *>(&m_historyModel); }
QAbstractItemModel *ClipboardController::favoritesModel() const { return const_cast<ClipboardListModel *>(&m_favoritesModel); }
QString ClipboardController::errorMessage() const { return m_favoritesStorageError.isEmpty() ? m_errorMessage : m_favoritesStorageError; }
bool ClipboardController::loading() const { return m_loading; }
bool ClipboardController::clearingHistory() const { return m_clearingHistory; }
QString ClipboardController::cliphistPath() const { return m_cliphistPath; }
QString ClipboardController::wlCopyPath() const { return m_wlCopyPath; }
QString ClipboardController::historyDatabasePath() const { return m_historyDatabasePath; }
QString ClipboardController::favoritesDirectory() const { return m_favoritesDirectory; }

void ClipboardController::setCliphistPath(QString path)
{
    if (path.isEmpty())
        return;
    m_cliphistPath = std::move(path);
    m_backend.setExecutable(m_cliphistPath);
}
void ClipboardController::setWlCopyPath(QString path)
{
    if (path.isEmpty())
        return;
    m_wlCopyPath = std::move(path);
    m_backend.setCopyExecutable(m_wlCopyPath);
}
void ClipboardController::setHistoryDatabasePath(QString path)
{
    m_historyDatabasePath = std::move(path);
    m_backend.setDatabasePath(m_historyDatabasePath);
}
void ClipboardController::setFavoritesDirectory(QString path) { m_favoritesDirectory = std::move(path); }

void ClipboardController::initialize()
{
    if (m_initialized)
        return;
    m_initialized = true;
    if (!m_favoritesDirectory.isEmpty())
        m_store.setDirectory(m_favoritesDirectory);
    m_backend.setExecutable(m_cliphistPath);
    m_backend.setCopyExecutable(m_wlCopyPath);
    m_backend.setDatabasePath(m_historyDatabasePath);

    QString errorText;
    if (!m_store.load(&errorText))
        setFavoritesStorageError(errorText);
    rebuildFavorites();
}

void ClipboardController::refresh()
{
    if (!m_initialized)
        initialize();
    if (m_refreshInFlight) {
        m_refreshQueued = true;
        return;
    }
    m_refreshInFlight = true;
    m_decodeQueuePending = false;
    setLoading(true);
    m_backend.refresh(++m_generation);
}

void ClipboardController::clearHistory()
{
    if (!m_initialized)
        initialize();
    if (m_clearingHistory)
        return;
    m_clearingHistory = true;
    emit clearingHistoryChanged();
    setError({});
    m_backend.wipe(++m_historyClearRequest);
}

bool ClipboardController::clearFavorites()
{
    if (!m_initialized)
        initialize();
    setError({});
    QString errorText;
    if (!m_store.clear(&errorText)) {
        setError(errorText.isEmpty() ? "Clipboard favorites could not be cleared." : errorText);
        return false;
    }
    return true;
}

void ClipboardController::prioritizeHistory(const QVariantList &keys)
{
    QStringList prioritized;
    for (const auto &value : keys) {
        const QString key = value.toString();
        if (m_history.contains(key) && m_history.value(key).payloadPath.isEmpty() && !m_decoding.contains(key))
            prioritized.append(key);
    }
    for (auto it = prioritized.crbegin(); it != prioritized.crend(); ++it)
        m_pendingDecode.removeAll(*it), m_pendingDecode.prepend(*it);
    startDecodeQueue();
}

void ClipboardController::acceptListing(quint64 generation, const QStringList &keys, const QStringList &previews, bool success)
{
    if (generation != m_generation)
        return;
    m_refreshInFlight = false;
    if (m_discardListingAfterHistoryClear) {
        m_discardListingAfterHistoryClear = false;
        m_refreshQueued = false;
        refresh();
        return;
    }
    if (!success) {
        startDecodeQueue();
        finishRefreshIfReady();
        return;
    }
    setError({});
    QStringList order;
    QHash<QString, ClipboardEntry> next;
    for (qsizetype i = 0; i < keys.size(); ++i) {
        const QString &key = keys.at(i);
        if (key.isEmpty() || next.contains(key))
            continue;
        ClipboardEntry entry = m_history.value(key);
        entry.key = key;
        if (entry.payloadPath.isEmpty() || entry.loading || entry.payloadKind.isEmpty())
            entry.previewText = previews.value(i);
        entry.loading = entry.payloadPath.isEmpty();
        entry.errorText.clear();
        entry.favorite = !entry.contentHash.isEmpty() && m_store.hashes().contains(entry.contentHash);
        next.insert(key, entry);
        order.append(key);
    }

    for (auto it = m_history.cbegin(); it != m_history.cend(); ++it) {
        if (!next.contains(it.key()) && !it.value().payloadPath.isEmpty())
            QFile::remove(it.value().payloadPath);
    }

    m_history = next;
    m_historyOrder = order;
    m_pendingDecode.clear();
    for (const auto &key : std::as_const(m_historyOrder))
        if (m_history.value(key).payloadPath.isEmpty())
            m_pendingDecode.append(key);
    for (auto it = m_pendingCopy.begin(); it != m_pendingCopy.end();) {
        if (!next.contains(*it) && !m_store.hashes().contains(*it)) {
            const QString key = *it;
            it = m_pendingCopy.erase(it);
            const QString message = "That clipboard entry has expired.";
            setError(message);
            emit copyCompleted(key, false, message);
        } else {
            ++it;
        }
    }
    for (auto it = m_pendingFavorite.begin(); it != m_pendingFavorite.end();) {
        if (!next.contains(it.key())) {
            const QString key = it.key();
            it = m_pendingFavorite.erase(it);
            emit operationCompleted("favorite", key, false);
        } else {
            ++it;
        }
    }
    rebuildHistoryModel();
    m_decodeQueuePending = true;
    QTimer::singleShot(50, this, [this, generation] {
        if (generation != m_generation)
            return;
        m_decodeQueuePending = false;
        startDecodeQueue();
        finishRefreshIfReady();
    });
    finishRefreshIfReady();
}

void ClipboardController::rebuildHistoryModel()
{
    QVector<ClipboardEntry> entries;
    entries.reserve(m_historyOrder.size());
    for (const auto &key : m_historyOrder)
        entries.append(m_history.value(key));
    m_historyModel.replace(entries);
}

void ClipboardController::enqueueDecode(const QString &key, bool prioritize)
{
    if (!m_history.contains(key) || !m_history.value(key).payloadPath.isEmpty() || m_decoding.contains(key))
        return;
    m_pendingDecode.removeAll(key);
    if (prioritize)
        m_pendingDecode.prepend(key);
    else
        m_pendingDecode.append(key);
    startDecodeQueue();
}

void ClipboardController::startDecodeQueue()
{
    int deferred = 0;
    while (m_decoding.size() < 2 && !m_pendingDecode.isEmpty()) {
        const QString key = m_pendingDecode.takeFirst();
        if (m_decoding.contains(key)) {
            m_pendingDecode.append(key);
            if (++deferred >= m_pendingDecode.size())
                break;
            continue;
        }
        deferred = 0;
        if (!m_history.contains(key) || !m_history.value(key).payloadPath.isEmpty())
            continue;
        const QString path = m_backend.createPayloadPath();
        if (path.isEmpty()) {
            auto entry = m_history.value(key);
            entry.loading = false;
            entry.errorText = "Could not create a private clipboard payload file.";
            m_history.insert(key, entry);
            m_historyModel.upsert(entry);
            applyPendingOperations(key);
            continue;
        }
        m_decoding.insert(key, m_generation);
        m_backend.decode(key, m_generation, path);
    }
}

void ClipboardController::acceptDecoded(const QString &key, quint64 generation, const QString &path, const QString &errorText)
{
    if (m_decoding.value(key, 0) != generation) {
        QFile::remove(path);
        return;
    }
    if (generation != m_generation || !m_history.contains(key)) {
        m_decoding.remove(key);
        QFile::remove(path);
        startDecodeQueue();
        return;
    }
    if (!errorText.isEmpty()) {
        QFile::remove(path);
        auto entry = m_history.value(key);
        entry.loading = false;
        entry.errorText = errorText;
        m_history.insert(key, entry);
        m_historyModel.upsert(entry);
        m_decoding.remove(key);
        setError(errorText);
        applyPendingOperations(key);
        startDecodeQueue();
        finishRefreshIfReady();
        return;
    }
    m_history[key].payloadPath = path;
    classifyHistory(key, generation, path);
}

void ClipboardController::classifyHistory(const QString &key, quint64 generation, const QString &path)
{
    auto *watcher = new QFutureWatcher<PayloadDescription>(this);
    connect(watcher, &QFutureWatcher<PayloadDescription>::finished, this, [this, watcher, key, generation, path] {
        const PayloadDescription description = watcher->result();
        watcher->deleteLater();
        if (m_decoding.value(key, 0) != generation) {
            QFile::remove(path);
            return;
        }
        m_decoding.remove(key);
        if (generation != m_generation || !m_history.contains(key)) {
            if (m_history.contains(key)) {
                ClipboardEntry entry = m_history.value(key);
                if (entry.payloadPath == path) {
                    entry.payloadPath.clear();
                    entry.loading = true;
                    entry.errorText.clear();
                    m_history.insert(key, entry);
                    m_historyModel.upsert(entry);
                }
            }
            QFile::remove(path);
            startDecodeQueue();
            finishRefreshIfReady();
            return;
        }
        ClipboardEntry entry = m_history.value(key);
        entry.payloadPath = path;
        applyDescription(entry, description);
        entry.favorite = !entry.contentHash.isEmpty() && m_store.hashes().contains(entry.contentHash);
        m_history.insert(key, entry);
        m_historyModel.upsert(entry);
        rebuildFavorites();
        applyPendingOperations(key);
        startDecodeQueue();
        finishRefreshIfReady();
    });
    watcher->setFuture(QtConcurrent::run(&PayloadClassifier::inspect, path, m_thumbnailDirectory));
}

void ClipboardController::classifyFavorite(const QString &hash, const QString &path)
{
    auto *watcher = new QFutureWatcher<PayloadDescription>(this);
    connect(watcher, &QFutureWatcher<PayloadDescription>::finished, this, [this, watcher, hash, path] {
        const PayloadDescription description = watcher->result();
        watcher->deleteLater();
        m_favoriteClassifying.remove(hash);
        if (!m_store.hashes().contains(hash)) {
            startFavoriteQueue();
            return;
        }
        ClipboardEntry entry;
        entry.key = hash;
        entry.payloadPath = path;
        entry.favorite = true;
        if (description.contentHash != hash) {
            const QString message = "A saved clipboard favorite payload does not match its content hash.";
            entry.previewText = "Saved favorite payload could not be verified.";
            entry.searchableText = entry.previewText + " " + hash;
            entry.payloadKind = "binary";
            entry.size = description.size;
            entry.errorText = message;
            entry.corrupted = true;
            setFavoritesStorageError(message);
        } else {
            applyDescription(entry, description);
        }
        m_favoriteEntries.insert(hash, entry);
        rebuildFavorites();
        if (m_pendingCopy.remove(hash)) {
            if (entry.corrupted)
                emit copyCompleted(hash, false, entry.errorText);
            else
                copyEntry(hash);
        }
        startFavoriteQueue();
    });
    watcher->setFuture(QtConcurrent::run(&PayloadClassifier::inspect, path, m_thumbnailDirectory));
}

void ClipboardController::enqueueFavoriteClassification(const QString &hash)
{
    if (!m_store.hashes().contains(hash) || m_favoriteClassifying.contains(hash)
        || m_pendingFavoriteClassifications.contains(hash))
        return;
    m_pendingFavoriteClassifications.append(hash);
    startFavoriteQueue();
}

void ClipboardController::startFavoriteQueue()
{
    while (m_favoriteClassifying.size() < 2 && !m_pendingFavoriteClassifications.isEmpty()) {
        const QString hash = m_pendingFavoriteClassifications.takeFirst();
        if (!m_store.hashes().contains(hash))
            continue;
        const QString path = m_store.payloadPath(hash);
        if (!QFileInfo::exists(path)) {
            const QString message = "A saved clipboard favorite payload is missing or unreadable.";
            ClipboardEntry entry;
            entry.key = hash;
            entry.previewText = "Saved favorite payload is unavailable.";
            entry.searchableText = entry.previewText + " " + hash;
            entry.payloadKind = "binary";
            entry.favorite = true;
            entry.errorText = message;
            entry.corrupted = true;
            m_favoriteEntries.insert(hash, entry);
            setFavoritesStorageError(message);
            continue;
        }
        m_favoriteClassifying.insert(hash);
        classifyFavorite(hash, path);
    }
}

void ClipboardController::applyDescription(ClipboardEntry &entry, const PayloadDescription &description)
{
    entry.previewText = description.previewText;
    entry.searchableText = description.searchableText;
    entry.payloadKind = description.payloadKind;
    entry.mimeType = description.mimeType.isEmpty() ? "application/octet-stream" : description.mimeType;
    entry.thumbnailUrl = description.thumbnailPath.isEmpty() ? QString() : QUrl::fromLocalFile(description.thumbnailPath).toString();
    entry.contentHash = description.contentHash;
    entry.size = description.size;
    entry.errorText = description.errorText;
    entry.loading = false;
}

void ClipboardController::rebuildFavorites()
{
    const QStringList hashes = m_store.hashes();
    for (auto it = m_pendingCopy.begin(); it != m_pendingCopy.end();) {
        if (!hashes.contains(*it) && !m_history.contains(*it)) {
            const QString key = *it;
            it = m_pendingCopy.erase(it);
            const QString message = "That favorite was removed before it could be copied.";
            setError(message);
            emit copyCompleted(key, false, message);
        } else {
            ++it;
        }
    }
    for (auto it = m_pendingFavoriteClassifications.begin(); it != m_pendingFavoriteClassifications.end();) {
        if (!hashes.contains(*it))
            it = m_pendingFavoriteClassifications.erase(it);
        else
            ++it;
    }
    for (auto it = m_favoriteEntries.begin(); it != m_favoriteEntries.end();) {
        if (!hashes.contains(it.key()))
            it = m_favoriteEntries.erase(it);
        else
            ++it;
    }
    QVector<ClipboardEntry> entries;
    entries.reserve(hashes.size());
    for (const auto &hash : hashes) {
        ClipboardEntry entry = m_favoriteEntries.value(hash);
        entry.key = hash;
        entry.favorite = true;
        if (entry.previewText.isEmpty()) {
            entry.previewText = "Loading favorite…";
            entry.loading = true;
            if (QFileInfo::exists(m_store.payloadPath(hash)))
                enqueueFavoriteClassification(hash);
            else {
                const QString message = "A saved clipboard favorite payload is missing or unreadable.";
                entry.previewText = "Saved favorite payload is unavailable.";
                entry.errorText = message;
                entry.loading = false;
                entry.corrupted = true;
                m_favoriteEntries.insert(hash, entry);
                setFavoritesStorageError(message);
            }
        }
        entries.append(entry);
    }
    m_favoritesModel.replace(entries);
    for (auto it = m_history.begin(); it != m_history.end(); ++it) {
        it->favorite = !it->contentHash.isEmpty() && hashes.contains(it->contentHash);
        m_historyModel.upsert(it.value());
    }
}

void ClipboardController::setFavorite(const QString &key, bool enabled)
{
    if (!m_initialized)
        initialize();
    if (m_history.contains(key)) {
        const auto entry = m_history.value(key);
        if (entry.contentHash.isEmpty()) {
            if (!entry.payloadPath.isEmpty() && !entry.errorText.isEmpty()) {
                setError(entry.errorText);
                emit operationCompleted("favorite", key, false);
                return;
            }
            m_pendingFavorite.insert(key, enabled);
            enqueueDecode(key, true);
            return;
        }
        const QString hash = entry.contentHash;
        QString errorText;
        const bool success = enabled
            ? m_store.add(hash, entry.payloadPath, &errorText)
            : m_store.remove(hash, &errorText);
        if (!success && !errorText.isEmpty())
            setError(errorText);
        emit operationCompleted("favorite", key, success);
        return;
    }
    const QString hash = key;
    QString errorText;
    const bool success = enabled
        ? false
        : m_store.remove(hash, &errorText);
    if (!success && !errorText.isEmpty())
        setError(errorText);
    emit operationCompleted("favorite", key, success);
}

void ClipboardController::moveFavorite(const QString &key, const QString &beforeKey)
{
    QString errorText;
    const bool success = m_store.moveBefore(key, beforeKey, &errorText);
    if (!success && !errorText.isEmpty())
        setError(errorText);
    emit operationCompleted("reorder", key, success);
}

void ClipboardController::copyEntry(const QString &key)
{
    if (!m_initialized)
        initialize();
    if (m_store.hashes().contains(key)) {
        ClipboardEntry entry = m_favoriteEntries.value(key);
        if (entry.corrupted) {
            const QString message = entry.errorText.isEmpty() ? "The saved clipboard favorite is unavailable." : entry.errorText;
            setError(message);
            emit copyCompleted(key, false, message);
            return;
        }
        if (entry.mimeType.isEmpty()) {
            m_pendingCopy.insert(key);
            enqueueFavoriteClassification(key);
            return;
        }
        copyPath(key, entry.payloadPath, entry.mimeType);
        return;
    }
    if (!m_history.contains(key)) {
        const QString message = "That clipboard entry has expired.";
        setError(message);
        emit copyCompleted(key, false, message);
        return;
    }
    const ClipboardEntry entry = m_history.value(key);
    if (entry.payloadPath.isEmpty() || entry.mimeType.isEmpty()) {
        m_pendingCopy.insert(key);
        enqueueDecode(key, true);
        return;
    }
    copyPath(key, entry.payloadPath, entry.mimeType);
}

void ClipboardController::copyPath(const QString &key, const QString &path, const QString &mimeType)
{
    if (!QFileInfo::exists(path)) {
        const QString message = "The saved clipboard payload is unavailable.";
        setError(message);
        emit copyCompleted(key, false, message);
        return;
    }
    ++m_copyRequest;
    m_backend.copy(key, path, mimeType, m_copyRequest);
}

void ClipboardController::applyPendingOperations(const QString &key)
{
    const ClipboardEntry entry = m_history.value(key);
    if (!entry.errorText.isEmpty()) {
        if (m_pendingFavorite.remove(key))
            emit operationCompleted("favorite", key, false);
        if (m_pendingCopy.remove(key))
            emit copyCompleted(key, false, entry.errorText);
        return;
    }
    if (m_pendingFavorite.contains(key)) {
        const bool enabled = m_pendingFavorite.take(key);
        setFavorite(key, enabled);
    }
    if (m_pendingCopy.remove(key))
        copyEntry(key);
}

void ClipboardController::finishRefreshIfReady()
{
    if (m_refreshInFlight || m_decodeQueuePending || !m_decoding.isEmpty())
        return;
    setLoading(false);
    if (m_refreshQueued) {
        m_refreshQueued = false;
        refresh();
    }
}

void ClipboardController::setError(const QString &message)
{
    if (m_errorMessage == message)
        return;
    const QString previous = errorMessage();
    m_errorMessage = message;
    if (previous != errorMessage())
        emit errorMessageChanged();
    if (!message.isEmpty())
        emit errorOccurred(message);
}

void ClipboardController::setFavoritesStorageError(const QString &message)
{
    const QString previous = errorMessage();
    m_favoritesStorageError = message;
    if (previous != errorMessage())
        emit errorMessageChanged();
    if (!message.isEmpty())
        emit errorOccurred(message);
}

void ClipboardController::setLoading(bool loading)
{
    if (m_loading == loading)
        return;
    m_loading = loading;
    emit loadingChanged();
}
