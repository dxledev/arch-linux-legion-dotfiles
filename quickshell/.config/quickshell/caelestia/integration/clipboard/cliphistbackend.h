#pragma once

#include <QObject>
#include <QStringList>
#include <QTemporaryDir>

class QProcess;

class CliphistBackend final : public QObject
{
    Q_OBJECT

public:
    explicit CliphistBackend(QObject *parent = nullptr);

    void setExecutable(QString executable);
    void setCopyExecutable(QString executable);
    void setDatabasePath(QString path);
    QString createPayloadPath();

    void refresh(quint64 generation);
    void wipe(quint64 request);
    void removeEntries(const QStringList &keys, quint64 request);
    void decode(const QString &key, quint64 generation, const QString &outputPath);
    void copy(const QString &key, const QString &payloadPath, const QString &mimeType, quint64 request);

signals:
    void listingReady(quint64 generation, QStringList keys, QStringList previews, bool success);
    void wipeFinished(quint64 request, bool success, QString errorText);
    void removeFinished(quint64 request, QStringList keys, bool success, QString errorText);
    void decodeReady(QString key, quint64 generation, QString payloadPath, QString errorText);
    void copyFinished(QString key, quint64 request, bool success, QString errorText);
    void error(QString message);

private:
    QStringList arguments(const QStringList &command) const;
    void finishListing(QProcess *process, quint64 generation, int exitCode);

    QString m_executable = "/usr/bin/cliphist";
    QString m_copyExecutable = "/usr/bin/wl-copy";
    QString m_databasePath;
    QTemporaryDir m_temporaryDirectory;
    bool m_listing = false;
};
