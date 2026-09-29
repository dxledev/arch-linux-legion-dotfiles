#include "clipboardfiltermodel.h"

#include "clipboardlistmodel.h"

#include <QtGlobal>

ClipboardFilterModel::ClipboardFilterModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
    connect(this, &QAbstractItemModel::rowsInserted, this, &ClipboardFilterModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &ClipboardFilterModel::countChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &ClipboardFilterModel::countChanged);
}

QString ClipboardFilterModel::query() const
{
    return m_query;
}

void ClipboardFilterModel::setQuery(QString query)
{
    if (m_query == query)
        return;
#if QT_VERSION >= QT_VERSION_CHECK(6, 10, 0)
    beginFilterChange();
    m_query = std::move(query);
    endFilterChange(QSortFilterProxyModel::Direction::Rows);
#else
    m_query = std::move(query);
    invalidateFilter();
#endif
    emit queryChanged();
    emit countChanged();
}

int ClipboardFilterModel::count() const
{
    return rowCount();
}

QString ClipboardFilterModel::keyAt(int row) const
{
    return row >= 0 && row < rowCount() ? data(index(row, 0), ClipboardListModel::KeyRole).toString() : QString();
}

bool ClipboardFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if (m_query.trimmed().isEmpty())
        return true;
    const QModelIndex sourceIndex = sourceModel()->index(sourceRow, 0, sourceParent);
    const QString searchable = sourceModel()->data(sourceIndex, ClipboardListModel::SearchableTextRole).toString();
    return searchable.contains(m_query.trimmed(), Qt::CaseInsensitive);
}
