#include "chromack-model.h"
#include "color-functions.h"
#include <QFile>
#include <QTemporaryDir>
#include <QtTest>
using namespace ChromackColors;

class ModelTest : public QObject {
    Q_OBJECT
private slots:
    void formatsAndScales() {
        QCOMPARE(toHexInputColor(QColor(32, 64, 128, 128)), QString("#80204080"));
        QCOMPARE(toPaletteFileColor(QColor(32, 64, 128, 128)), QString("#20408080"));
        QCOMPARE(toRgbaColor(QColor(32, 64, 128, 128)), QString("rgba(32, 64, 128, 0.5)"));
        QVERIFY(!parseColorValue("invalid").isValid());
        for (const auto &base : {QColor("#000000"), QColor("#ffffff"), QColor("#f44336"), QColor(32,64,128,128)}) {
            const auto shades = buildShadeScale(base, 12);
            QCOMPARE(shades.first(), QColor(0,0,0,base.alpha()));
            QCOMPARE(shades.last(), base);
            QCOMPARE(buildTintScale(base,12).last(), QColor(255,255,255,base.alpha()));
            QCOMPARE(buildTerminal24FromBase(base).size(), 24);
            QCOMPARE(theoryWheelColors(base).size(), 24);
            QCOMPARE(monochromaticTheory(base).size(), 7);
        }
    }
    void persistenceAndExport() {
        QTemporaryDir directory;
        QVERIFY(directory.isValid());
        qputenv("SHELL_CHROMACK_CONFIG_DIR", directory.path().toUtf8());
        QFile config(directory.filePath("config.toml"));
        QVERIFY(config.open(QIODevice::WriteOnly));
        config.write(("[paths]\nstyle_css = \"" + directory.filePath("style.css") + "\"\ncolors_css = \"" + directory.filePath("colors.css") + "\"\nmaterial_css = \"" + directory.filePath("material.css") + "\"\nactive_color_file = \"" + directory.filePath("active.txt") + "\"\nrecent_colors_file = \"" + directory.filePath("recent.txt") + "\"\npalette_directory = \"" + directory.filePath("palettes") + "\"\n").toUtf8());
        config.close();
        ChromackModel model;
        QVERIFY(model.setColor("rgba(32, 64, 128, 0.5)", true, false));
        QCOMPARE(model.state()["palette"].toList().size(), 26);
        const auto previous = model.state()["hex"];
        QVERIFY(!model.generate("not-a-color"));
        QCOMPARE(model.state()["hex"], previous);
        QVERIFY(model.setColor("#ffffff"));
        QCOMPARE(model.state()["alpha"].toInt(), 128);
        const auto colorBeforeAlpha = model.state()["color"].value<QColor>();
        model.setAlpha(64);
        QCOMPARE(model.state()["color"].value<QColor>().rgb(), colorBeforeAlpha.rgb());
        QVERIFY(model.generate("#ffffff"));
        QCOMPARE(model.state()["alpha"].toInt(), 64);
        QCOMPARE(model.state()["recent"].toList().size(), 1);
        model.setAlpha(128);
        QVERIFY(model.flush());
        ChromackModel restored;
        QCOMPARE(restored.state()["hex"], model.state()["hex"]);
        QCOMPARE(restored.state()["recent"].toList().size(), 1);
        const auto first = model.savePalette("../A \"test\"");
        const auto second = model.savePalette("../A \"test\"");
        QVERIFY(!first.isEmpty());
        QVERIFY(second.endsWith("-2.toml"));
        QVERIFY(first.startsWith(directory.filePath("palettes/")));
        QFile saved(first);
        QVERIFY(saved.open(QIODevice::ReadOnly));
        const auto data = saved.readAll();
        QVERIFY(data.contains("foreground = "));
        QVERIFY(data.contains("color_23 = "));
        QVERIFY(data.contains("base = \"#ffffff80\""));
        QVERIFY(!model.setColor("#wrong"));
        QFile denied(directory.filePath("palettes/block"));
        QVERIFY(denied.open(QIODevice::WriteOnly));
        denied.close();
        QVERIFY(config.open(QIODevice::Append));
        config.write(("palette_directory = \"" + directory.filePath("palettes/block/child") + "\"\n").toUtf8());
        config.close();
        model.reload();
        QSignalSpy errors(&model, &ChromackModel::error);
        QVERIFY(model.savePalette("no").isEmpty());
        QCOMPARE(errors.size(), 1);
    }
};
QTEST_MAIN(ModelTest)
#include "model.moc"
