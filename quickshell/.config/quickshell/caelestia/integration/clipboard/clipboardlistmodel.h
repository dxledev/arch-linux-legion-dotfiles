#pragma once

#include "clipboardentry.h"

#include <QAbstractListModel>
#include <QHash>
#include <QVector>

class ClipboardListModel final : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(bool favorites READ favorites CONSTANT)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(bool processing READ processing NOTIFY processingChanged)

public:
    enum Role {
        KeyRole = Qt::UserRole + 1,
        PreviewTextRole,
        SearchableTextRole,
        PayloadKindRole,
        MimeTypeRole,
        SizeRole,
        ThumbnailUrlRole,
        FavoriteRole,
        LoadingRole,
        ErrorTextRole,
        ContentTextRole,
        QrTextRole,
        ImageUrlRole,
        ContentHashRole
    };
    Q_ENUM(Role)

    explicit ClipboardListModel(bool favorites, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    bool favorites() const;
    int count() const;
    bool processing() const;
    QString keyAt(int row) const;
    int rowForKey(const QString &key) const;
    ClipboardEntry entry(const QString &key) const;
    QVector<ClipboardEntry> entries() const;
    void replace(const QVector<ClipboardEntry> &entries);
    void upsert(const ClipboardEntry &entry);
    void remove(const QString &key);

signals:
    void countChanged();
    void processingChanged();

private:
    void rebuildRowIndex();

    bool m_favorites;
    QVector<ClipboardEntry> m_entries;
    QHash<QString, int> m_rows;
};
