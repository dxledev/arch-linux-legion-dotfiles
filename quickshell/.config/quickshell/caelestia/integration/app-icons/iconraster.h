#pragma once

#include <QQuickPaintedItem>
#include <QColor>
#include <QImage>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

class IconRaster : public QQuickPaintedItem {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QColor tint READ tint WRITE setTint NOTIFY tintChanged)
    Q_PROPERTY(bool light READ light WRITE setLight NOTIFY lightChanged)
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
    Q_PROPERTY(QSize imageSize READ imageSize NOTIFY readyChanged)

public:
    using QQuickPaintedItem::QQuickPaintedItem;
    QColor tint() const { return m_tint; }
    bool light() const { return m_light; }
    bool ready() const { return !m_colored.isNull(); }
    QSize imageSize() const { return m_colored.size(); }
    void setTint(const QColor &tint);
    void setLight(bool light);
    Q_INVOKABLE void setImage(const QImage &image, const QString &key);
    Q_INVOKABLE bool restore(const QString &key);
    Q_INVOKABLE QVariantMap cacheStats() const;
    Q_INVOKABLE void clear();
    void paint(QPainter *painter) override;

signals:
    void tintChanged();
    void lightChanged();
    void readyChanged();

private:
    void refresh();
    QColor m_tint;
    bool m_light = false;
    QString m_key;
    QImage m_original;
    QImage m_colored;
};
