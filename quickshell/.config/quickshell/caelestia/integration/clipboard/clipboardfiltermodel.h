#pragma once

#include <QSortFilterProxyModel>
#include <QtQml/qqmlregistration.h>

class ClipboardFilterModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY queryChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    explicit ClipboardFilterModel(QObject *parent = nullptr);

    QString query() const;
    void setQuery(QString query);
    int count() const;
    Q_INVOKABLE QString keyAt(int row) const;

signals:
    void queryChanged();
    void countChanged();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;

private:
    QString m_query;
};
