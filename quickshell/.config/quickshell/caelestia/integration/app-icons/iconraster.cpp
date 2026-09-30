#include "iconraster.h"
#include "iconcolorization.h"
#include "iconcache.h"

#include <QPainter>

void IconRaster::setTint(const QColor &tint) {
    if (m_tint == tint)
        return;
    m_tint = tint;
    emit tintChanged();
    refresh();
}

void IconRaster::setLight(bool light) {
    if (m_light == light)
        return;
    m_light = light;
    emit lightChanged();
    refresh();
}

void IconRaster::setImage(const QImage &image, const QString &key) {
    m_key = iconSourceKey(key);
    m_original = boundedIconImage(image);
    cacheIconSource(m_key, m_original);
    refresh();
}

bool IconRaster::restore(const QString &key) {
    m_key = iconSourceKey(key);
    m_original = cachedIconSource(m_key);
    refresh();
    return ready();
}

QVariantMap IconRaster::cacheStats() const { return iconCacheStats(); }

void IconRaster::clear() {
    m_key.clear();
    m_original = {};
    refresh();
}

void IconRaster::refresh() {
    const QString key = m_key + QLatin1Char('|') + QString::number(m_tint.rgba())
        + QLatin1Char('|') + QString::number(m_light);
    m_colored = m_original.isNull() ? QImage{} : cachedIconTint(key);
    if (!m_original.isNull() && m_colored.isNull()) {
        m_colored = colorizeIcon(m_original, m_tint, m_light);
        cacheIconTint(key, m_colored);
    }
    emit readyChanged();
    update();
}

void IconRaster::paint(QPainter *painter) {
    if (!m_colored.isNull()) {
        painter->setRenderHint(QPainter::SmoothPixmapTransform);
        painter->drawImage(boundingRect(), m_colored);
    }
}
