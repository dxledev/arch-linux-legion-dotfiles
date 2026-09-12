#pragma once
#include "ChromackConfig.h"
#include <QColor>
#include <QElapsedTimer>
#include <QTimer>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

class ChromackModel : public QObject {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QVariantMap state READ state NOTIFY changed)
public:
    explicit ChromackModel(QObject *parent = nullptr);
    QVariantMap state() const;
    Q_INVOKABLE bool setColor(const QString &value, bool recent = false, bool preserveAlpha = true);
    Q_INVOKABLE void selectMaterial(int index);
    Q_INVOKABLE void setHsv(int hue, double saturation, double value, int alpha);
    Q_INVOKABLE void setAlpha(int alpha);
    Q_INVOKABLE bool generate(const QString &value);
    Q_INVOKABLE void copy(const QString &value);
    Q_INVOKABLE QString savePalette(const QString &name);
    Q_INVOKABLE bool flush();
    Q_INVOKABLE void reload();
    Q_INVOKABLE QColor parse(const QString &value) const;
signals:
    void changed();
    void error(const QString &message);
private:
    void loadStyle();
    void loadCaches();
    void updateColor(const QColor &color, bool recent);
    void notifyColor(const QString &value, const QColor &color);
    void pushRecent(const QColor &color);
    bool writeCache();
    bool writeFile(const QString &path, const QByteArray &data);
    bool writeCss(const QString &path, bool material, bool combined);
    QString expandPath(QString path) const;
    QColor active() const;
    QVariantList palette() const;
    QVariantList colorList(const QList<QColor> &colors) const;
    QString resolvedStyle(const QString &key) const;
    ChromackConfigLoader loader_;
    QHash<QString, QString> variables_;
    QStringList materialKeys_;
    QString activeKey_;
    QList<QColor> recent_;
    int hue_ = 0;
    QString status_;
    QString notificationId_;
    QElapsedTimer notificationAge_;
    QTimer cacheTimer_;
};
