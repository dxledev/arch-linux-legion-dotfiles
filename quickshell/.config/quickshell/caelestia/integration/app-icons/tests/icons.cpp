#include "iconcolorization.h"
#include "iconraster.h"
#include "iconcache.h"

#include <QFile>
#include <QTemporaryDir>
#include <QTest>
#include <QUrl>

class IconTests : public QObject {
    Q_OBJECT

private slots:
    void boundsLargeImages() {
        QImage image(4000, 2000, QImage::Format_RGBA8888);
        image.fill(Qt::red);
        image.setDevicePixelRatio(2);
        const auto bounded = boundedIconImage(image);
        QCOMPARE(bounded.size(), QSize(256, 128));
        QCOMPARE(bounded.devicePixelRatio(), 1.0);
        QCOMPARE(image.size(), QSize(4000, 2000));
    }

    void preservesAlphaAndOriginal() {
        QImage image(4, 1, QImage::Format_RGBA8888);
        image.setPixelColor(0, 0, QColor(0, 0, 0, 255));
        image.setPixelColor(1, 0, QColor(255, 255, 255, 255));
        image.setPixelColor(2, 0, QColor(255, 0, 0, 127));
        image.setPixelColor(3, 0, QColor(0, 0, 255, 7));
        const auto colored = colorizeIcon(image, QColor(144, 176, 208), false);
        for (int x = 0; x < 4; x++)
            QCOMPARE(colored.pixelColor(x, 0).alpha(), image.pixelColor(x, 0).alpha());
        QCOMPARE(colored.pixelColor(0, 0), QColor(40, 49, 58));
        QCOMPARE(colored.pixelColor(3, 0), image.pixelColor(3, 0));
        QCOMPARE(image.pixelColor(2, 0), QColor(255, 0, 0, 127));
    }

    void reusesCacheAcrossDelegates() {
        QImage image(32, 32, QImage::Format_RGBA8888);
        image.fill(Qt::red);
        const QString key = QStringLiteral("test-shared|32x32|1");
        const QColor tint(144, 176, 208);
        {
            IconRaster initial;
            initial.setTint(tint);
            initial.setImage(image, key);
            QVERIFY(initial.ready());
        }
        const auto before = iconCacheStats();
        IconRaster restored;
        restored.setTint(tint);
        QVERIFY(restored.restore(key));
        QCOMPARE(restored.imageSize(), QSize(32, 32));
        const auto after = restored.cacheStats();
        QCOMPARE(after[QStringLiteral("sourceHits")].toLongLong(), before[QStringLiteral("sourceHits")].toLongLong() + 1);
        QCOMPARE(after[QStringLiteral("tintHits")].toLongLong(), before[QStringLiteral("tintHits")].toLongLong() + 1);
    }

    void invalidatesModifiedFiles() {
        QTemporaryDir directory;
        QFile file(directory.filePath(QStringLiteral("icon.png")));
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write("a");
        file.close();
        const auto key = QUrl::fromLocalFile(file.fileName()).toString() + QStringLiteral("|32x32|1");
        const auto before = iconSourceKey(key);
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write("ab");
        file.close();
        QVERIFY(iconSourceKey(key) != before);
    }

    void evictsWithinBudget() {
        QImage image(256, 256, QImage::Format_RGBA8888);
        image.fill(Qt::blue);
        IconRaster raster;
        raster.setTint(Qt::white);
        for (int i = 0; i < 300; i++)
            raster.setImage(image, QStringLiteral("test-eviction-%1").arg(i));
        const auto stats = raster.cacheStats();
        QVERIFY(stats[QStringLiteral("sourceBytes")].toInt() <= 8 * 1024 * 1024);
        QVERIFY(stats[QStringLiteral("tintBytes")].toInt() <= 8 * 1024 * 1024);
        QVERIFY(!raster.restore(QStringLiteral("test-eviction-0")));
        QVERIFY(raster.restore(QStringLiteral("test-eviction-299")));
    }
};

QTEST_MAIN(IconTests)
#include "icons.moc"
