#include "clipboardlistmodel.h"

#include <algorithm>
#include <QSet>

namespace {

bool sameEntry(const ClipboardEntry &left, const ClipboardEntry &right)
{
    return left.key == right.key
        && left.previewText == right.previewText
        && left.searchableText == right.searchableText
        && left.contentText == right.contentText
        && left.qrText == right.qrText
        && left.imageUrl == right.imageUrl
        && left.payloadKind == right.payloadKind
        && left.mimeType == right.mimeType
        && left.thumbnailUrl == right.thumbnailUrl
        && left.contentHash == right.contentHash
        && left.payloadPath == right.payloadPath
        && left.errorText == right.errorText
        && left.size == right.size
        && left.favorite == right.favorite
        && left.loading == right.loading
        && left.corrupted == right.corrupted;
}

}

ClipboardListModel::ClipboardListModel(bool favorites, QObject *parent)
    : QAbstractListModel(parent), m_favorites(favorites)
{
}

int ClipboardListModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_entries.size();
}

QVariant ClipboardListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_entries.size())
        return {};

    const auto &entry = m_entries.at(index.row());
    switch (role) {
    case KeyRole: return entry.key;
    case PreviewTextRole: return entry.previewText;
    case SearchableTextRole: return entry.searchableText;
    case PayloadKindRole: return entry.payloadKind;
    case MimeTypeRole: return entry.mimeType;
    case SizeRole: return entry.size;
    case ThumbnailUrlRole: return entry.thumbnailUrl;
    case FavoriteRole: return entry.favorite;
    case LoadingRole: return entry.loading;
    case ErrorTextRole: return entry.errorText;
    case ContentTextRole: return entry.contentText;
    case QrTextRole: return entry.qrText;
    case ImageUrlRole: return entry.imageUrl;
    case ContentHashRole: return entry.contentHash;
    default: return {};
    }
}

QHash<int, QByteArray> ClipboardListModel::roleNames() const
{
    return {{KeyRole, "key"}, {PreviewTextRole, "previewText"},
            {SearchableTextRole, "searchableText"}, {PayloadKindRole, "payloadKind"},
            {MimeTypeRole, "mimeType"}, {SizeRole, "size"},
            {ThumbnailUrlRole, "thumbnailUrl"}, {FavoriteRole, "favorite"},
            {LoadingRole, "loading"}, {ErrorTextRole, "errorText"},
            {ContentTextRole, "contentText"}, {QrTextRole, "qrText"}, {ImageUrlRole, "imageUrl"},
            {ContentHashRole, "contentHash"}};
}

bool ClipboardListModel::favorites() const
{
    return m_favorites;
}

int ClipboardListModel::count() const
{
    return m_entries.size();
}

bool ClipboardListModel::processing() const
{
    return std::any_of(m_entries.cbegin(), m_entries.cend(), [](const ClipboardEntry &entry) {
        return entry.loading;
    });
}

QString ClipboardListModel::keyAt(int row) const
{
    return row >= 0 && row < m_entries.size() ? m_entries.at(row).key : QString();
}

int ClipboardListModel::rowForKey(const QString &key) const
{
    return m_rows.value(key, -1);
}

ClipboardEntry ClipboardListModel::entry(const QString &key) const
{
    const int row = rowForKey(key);
    return row >= 0 ? m_entries.at(row) : ClipboardEntry{};
}

QVector<ClipboardEntry> ClipboardListModel::entries() const
{
    return m_entries;
}

void ClipboardListModel::replace(const QVector<ClipboardEntry> &entries)
{
    const int previousCount = m_entries.size();
    const bool wasProcessing = processing();

    if (m_entries.isEmpty() && !entries.isEmpty()) {
        beginResetModel();
        m_entries = entries;
        rebuildRowIndex();
        endResetModel();
    } else {
        QSet<QString> desiredKeys;
        desiredKeys.reserve(entries.size());
        for (const auto &entry : entries)
            desiredKeys.insert(entry.key);

        for (int row = m_entries.size() - 1; row >= 0; --row) {
            if (desiredKeys.contains(m_entries.at(row).key))
                continue;
            beginRemoveRows({}, row, row);
            m_entries.removeAt(row);
            rebuildRowIndex();
            endRemoveRows();
        }

        for (int targetRow = 0; targetRow < entries.size(); ++targetRow) {
            const ClipboardEntry &desired = entries.at(targetRow);
            if (targetRow < m_entries.size() && m_entries.at(targetRow).key == desired.key) {
                if (!sameEntry(m_entries.at(targetRow), desired)) {
                    m_entries[targetRow] = desired;
                    emit dataChanged(index(targetRow), index(targetRow));
                }
                continue;
            }

            const int currentRow = rowForKey(desired.key);
            if (currentRow > targetRow) {
                beginMoveRows({}, currentRow, currentRow, {}, targetRow);
                m_entries.insert(targetRow, m_entries.takeAt(currentRow));
                rebuildRowIndex();
                endMoveRows();
                if (!sameEntry(m_entries.at(targetRow), desired)) {
                    m_entries[targetRow] = desired;
                    emit dataChanged(index(targetRow), index(targetRow));
                }
            } else {
                beginInsertRows({}, targetRow, targetRow);
                m_entries.insert(targetRow, desired);
                rebuildRowIndex();
                endInsertRows();
            }
        }
    }

    if (previousCount != m_entries.size())
        emit countChanged();
    if (wasProcessing != processing())
        emit processingChanged();
}

void ClipboardListModel::upsert(const ClipboardEntry &entry)
{
    const int row = rowForKey(entry.key);
    if (row < 0) {
        const bool wasProcessing = processing();
        const int next = m_entries.size();
        beginInsertRows({}, next, next);
        m_entries.append(entry);
        m_rows.insert(entry.key, next);
        endInsertRows();
        emit countChanged();
        if (wasProcessing != processing())
            emit processingChanged();
        return;
    }

    const bool wasProcessing = processing();
    m_entries[row] = entry;
    emit dataChanged(index(row), index(row));
    if (wasProcessing != processing())
        emit processingChanged();
}

void ClipboardListModel::remove(const QString &key)
{
    const int row = rowForKey(key);
    if (row < 0)
        return;

    const bool wasProcessing = processing();
    beginRemoveRows({}, row, row);
    m_entries.removeAt(row);
    rebuildRowIndex();
    endRemoveRows();
    emit countChanged();
    if (wasProcessing != processing())
        emit processingChanged();
}

void ClipboardListModel::rebuildRowIndex()
{
    m_rows.clear();
    for (qsizetype row = 0; row < m_entries.size(); ++row)
        m_rows.insert(m_entries.at(row).key, static_cast<int>(row));
}
