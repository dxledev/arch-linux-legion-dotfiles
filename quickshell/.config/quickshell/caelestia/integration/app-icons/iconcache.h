#pragma once

#include <QImage>
#include <QVariantMap>

QString iconSourceKey(const QString &key);
QImage cachedIconSource(const QString &key);
QImage cachedIconTint(const QString &key);
void cacheIconSource(const QString &key, const QImage &image);
void cacheIconTint(const QString &key, const QImage &image);
QVariantMap iconCacheStats();
