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

QString ClipboardFilterModel::kind() const
{
    return m_kind;
}

void ClipboardFilterModel::setKind(QString kind)
{
    if (m_kind == kind)
        return;
#if QT_VERSION >= QT_VERSION_CHECK(6, 10, 0)
    beginFilterChange();
    m_kind = std::move(kind);
    endFilterChange(QSortFilterProxyModel::Direction::Rows);
#else
    m_kind = std::move(kind);
    invalidateFilter();
#endif
    emit kindChanged();
    emit countChanged();
}

QVariantMap ClipboardFilterModel::entryAt(int row) const
{
    QVariantMap entry;
    if (row < 0 || row >= rowCount())
        return entry;
    const auto roles = roleNames();
    for (auto role = roles.cbegin(); role != roles.cend(); ++role)
        entry.insert(QString::fromUtf8(role.value()), data(index(row, 0), role.key()));
    return entry;
}

QString ClipboardFilterModel::keyAt(int row) const
{
    return row >= 0 && row < rowCount() ? data(index(row, 0), ClipboardListModel::KeyRole).toString() : QString();
}

bool ClipboardFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    const QModelIndex sourceIndex = sourceModel()->index(sourceRow, 0, sourceParent);
    if (!m_kind.isEmpty() && sourceModel()->data(sourceIndex, ClipboardListModel::PayloadKindRole).toString() != m_kind)
        return false;
    if (m_query.trimmed().isEmpty())
        return true;
    const QString searchable = sourceModel()->data(sourceIndex, ClipboardListModel::SearchableTextRole).toString();
    return searchable.contains(m_query.trimmed(), Qt::CaseInsensitive);
}
