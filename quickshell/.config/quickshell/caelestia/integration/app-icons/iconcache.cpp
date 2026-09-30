#include "iconcache.h"

#include <QCache>
#include <QDateTime>
#include <QFileInfo>
#include <QUrl>
#include <algorithm>

namespace {
struct ImageCache {
    QCache<QString, QImage> images{8 * 1024 * 1024};
    qlonglong hits = 0;

    QImage find(const QString &key) {
        if (const auto *image = images.object(key)) {
            ++hits;
            return *image;
        }
        return {};
    }

    void insert(const QString &key, const QImage &image) {
        if (!image.isNull()) {
            // A minimum charge also bounds the number of small cache entries and their metadata.
            const int cost = std::max(32 * 1024, static_cast<int>(image.sizeInBytes()));
            images.insert(key, new QImage(image), cost);
        }
    }
};

ImageCache sources;
ImageCache tints;
}

QString iconSourceKey(const QString &key) {
    const QUrl source(key.section(QLatin1Char('|'), 0, 0));
    if (!source.isLocalFile())
        return key;
    const QFileInfo file(source.toLocalFile());
    return key + QLatin1Char('|') + QString::number(file.lastModified().toMSecsSinceEpoch())
        + QLatin1Char('|') + QString::number(file.size());
}

QImage cachedIconSource(const QString &key) { return sources.find(key); }
QImage cachedIconTint(const QString &key) { return tints.find(key); }
void cacheIconSource(const QString &key, const QImage &image) { sources.insert(key, image); }
void cacheIconTint(const QString &key, const QImage &image) { tints.insert(key, image); }

QVariantMap iconCacheStats() {
    return {{QStringLiteral("sourceHits"), sources.hits}, {QStringLiteral("tintHits"), tints.hits},
        {QStringLiteral("sourceBytes"), sources.images.totalCost()},
        {QStringLiteral("tintBytes"), tints.images.totalCost()},
        {QStringLiteral("sourceCount"), sources.images.size()},
        {QStringLiteral("tintCount"), tints.images.size()}};
}
