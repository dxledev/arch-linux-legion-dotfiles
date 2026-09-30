#pragma once

#include <QSortFilterProxyModel>
#include <QtQml/qqmlregistration.h>

class ClipboardFilterModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY queryChanged)
    Q_PROPERTY(QString kind READ kind WRITE setKind NOTIFY kindChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    explicit ClipboardFilterModel(QObject *parent = nullptr);

    QString query() const;
    void setQuery(QString query);
    int count() const;
    QString kind() const;
    void setKind(QString kind);
    Q_INVOKABLE QString keyAt(int row) const;
    Q_INVOKABLE QVariantMap entryAt(int row) const;

signals:
    void queryChanged();
    void kindChanged();
    void countChanged();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;

private:
    QString m_query;
    QString m_kind;
};
