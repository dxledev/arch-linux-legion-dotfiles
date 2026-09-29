#pragma once

#include <QObject>
#include <QStringList>

class FavoritesStore final : public QObject
{
    Q_OBJECT

public:
    explicit FavoritesStore(QObject *parent = nullptr);

    void setDirectory(QString directory);
    QString directory() const;
    bool load(QString *errorText = nullptr);
    QStringList hashes() const;
    QString payloadPath(const QString &hash) const;
    bool add(const QString &hash, const QString &sourcePath, QString *errorText = nullptr);
    bool remove(const QString &hash, QString *errorText = nullptr);
    bool clear(QString *errorText = nullptr);
    bool moveBefore(const QString &hash, const QString &beforeHash, QString *errorText = nullptr);

signals:
    void changed();
    void error(QString message);

private:
    bool ensureDirectory(QString *errorText) const;
    bool writeManifest(const QStringList &hashes, QString *errorText) const;
    bool validHash(const QString &hash) const;

    QString m_directory;
    QStringList m_hashes;
    bool m_healthy = true;
};
