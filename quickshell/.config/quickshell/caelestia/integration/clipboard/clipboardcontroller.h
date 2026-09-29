#pragma once

#include "clipboardlistmodel.h"
#include "cliphistbackend.h"
#include "favoritesstore.h"
#include "payloadclassifier.h"

#include <QObject>
#include <QSet>
#include <QStringList>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

class ClipboardController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QAbstractItemModel *historyModel READ historyModel CONSTANT)
    Q_PROPERTY(QAbstractItemModel *favoritesModel READ favoritesModel CONSTANT)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(bool clearingHistory READ clearingHistory NOTIFY clearingHistoryChanged)
    Q_PROPERTY(QString cliphistPath READ cliphistPath WRITE setCliphistPath)
    Q_PROPERTY(QString wlCopyPath READ wlCopyPath WRITE setWlCopyPath)
    Q_PROPERTY(QString historyDatabasePath READ historyDatabasePath WRITE setHistoryDatabasePath)
    Q_PROPERTY(QString favoritesDirectory READ favoritesDirectory WRITE setFavoritesDirectory)

public:
    explicit ClipboardController(QObject *parent = nullptr);

    QAbstractItemModel *historyModel() const;
    QAbstractItemModel *favoritesModel() const;
    QString errorMessage() const;
    bool loading() const;
    bool clearingHistory() const;
    QString cliphistPath() const;
    QString wlCopyPath() const;
    QString historyDatabasePath() const;
    QString favoritesDirectory() const;

    void setCliphistPath(QString path);
    void setWlCopyPath(QString path);
    void setHistoryDatabasePath(QString path);
    void setFavoritesDirectory(QString path);

    Q_INVOKABLE void initialize();
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void clearHistory();
    Q_INVOKABLE bool clearFavorites();
    Q_INVOKABLE void prioritizeHistory(const QVariantList &keys);
    Q_INVOKABLE void copyEntry(const QString &key);
    Q_INVOKABLE void setFavorite(const QString &key, bool enabled);
    Q_INVOKABLE void moveFavorite(const QString &key, const QString &beforeKey);

signals:
    void errorMessageChanged();
    void loadingChanged();
    void clearingHistoryChanged();
    void historyClearCompleted(bool success, QString errorText);
    void operationCompleted(QString operation, QString key, bool success);
    void copyCompleted(QString key, bool success, QString errorText);
    void errorOccurred(QString message);

private:
    void setError(const QString &message);
    void setFavoritesStorageError(const QString &message);
    void setLoading(bool loading);
    void acceptListing(quint64 generation, const QStringList &keys, const QStringList &previews, bool success);
    void rebuildHistoryModel();
    void enqueueDecode(const QString &key, bool prioritize);
    void startDecodeQueue();
    void acceptDecoded(const QString &key, quint64 generation, const QString &path, const QString &errorText);
    void classifyHistory(const QString &key, quint64 generation, const QString &path);
    void classifyFavorite(const QString &hash, const QString &path);
    void enqueueFavoriteClassification(const QString &hash);
    void startFavoriteQueue();
    void applyDescription(ClipboardEntry &entry, const PayloadDescription &description);
    void rebuildFavorites();
    void finishRefreshIfReady();
    void copyPath(const QString &key, const QString &path, const QString &mimeType);
    void applyPendingOperations(const QString &key);

    ClipboardListModel m_historyModel;
    ClipboardListModel m_favoritesModel;
    CliphistBackend m_backend;
    FavoritesStore m_store;
    QHash<QString, ClipboardEntry> m_history;
    QHash<QString, ClipboardEntry> m_favoriteEntries;
    QStringList m_historyOrder;
    QStringList m_pendingDecode;
    QHash<QString, quint64> m_decoding;
    QHash<QString, bool> m_pendingFavorite;
    QSet<QString> m_pendingCopy;
    QSet<QString> m_favoriteClassifying;
    QStringList m_pendingFavoriteClassifications;
    QString m_errorMessage;
    QString m_cliphistPath = "/usr/bin/cliphist";
    QString m_wlCopyPath = "/usr/bin/wl-copy";
    QString m_historyDatabasePath;
    QString m_favoritesDirectory;
    QString m_thumbnailDirectory;
    QString m_favoritesStorageError;
    quint64 m_generation = 0;
    quint64 m_copyRequest = 0;
    bool m_initialized = false;
    bool m_refreshInFlight = false;
    bool m_refreshQueued = false;
    bool m_decodeQueuePending = false;
    bool m_loading = false;
    bool m_clearingHistory = false;
    bool m_discardListingAfterHistoryClear = false;
    quint64 m_historyClearRequest = 0;
};
