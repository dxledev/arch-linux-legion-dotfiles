#include "clipboardcontroller.h"
#include "clipboardfiltermodel.h"
#include "clipboardlistmodel.h"
#include "favoritesstore.h"
#include "payloadclassifier.h"

#include <QDir>
#include <QCryptographicHash>
#include <QAbstractItemModelTester>
#include <QFile>
#include <QFileInfo>
#include <QImage>
#include <QTemporaryDir>
#include <QtTest>

class ClipboardTest final : public QObject
{
    Q_OBJECT

private:
    QTemporaryDir m_root;
    QString m_cliphist;
    QString m_copier;
    QString m_data;
    QString m_payloads;
    QString m_list;

    bool writeFile(const QString &path, const QByteArray &data, QFileDevice::Permissions permissions = QFileDevice::ReadOwner | QFileDevice::WriteOwner)
    {
        QFile file(path);
        if (!file.open(QIODevice::WriteOnly))
            return false;
        if (file.write(data) != data.size())
            return false;
        file.close();
        return file.setPermissions(permissions);
    }

    bool writeListing(const QList<QPair<QString, QString>> &entries)
    {
        QByteArray data;
        for (const auto &entry : entries)
            data += entry.first.toUtf8() + '\t' + entry.second.toUtf8() + '\n';
        return writeFile(m_list, data);
    }

    QVariant role(const QAbstractItemModel *model, int row, const char *name) const
    {
        const auto roles = model->roleNames();
        for (auto it = roles.cbegin(); it != roles.cend(); ++it)
            if (it.value() == name)
                return model->index(row, 0).data(it.key());
        return {};
    }

    void configure(ClipboardController &result, const QString &favoriteDirectory)
    {
        result.setCliphistPath(m_cliphist);
        result.setWlCopyPath(m_copier);
        result.setHistoryDatabasePath(QDir(m_data).filePath("isolated-cliphist.db"));
        result.setFavoritesDirectory(favoriteDirectory);
    }

private slots:
    void initTestCase()
    {
        QVERIFY(m_root.isValid());
        m_data = QDir(m_root.path()).filePath("test-data");
        m_payloads = QDir(m_data).filePath("payloads");
        QVERIFY(QDir().mkpath(m_payloads));
        m_list = QDir(m_data).filePath("history.tsv");
        m_cliphist = QDir(m_data).filePath("cliphist-stub");
        m_copier = QDir(m_data).filePath("wl-copy-stub");
        const QByteArray cliphist = R"(#!/usr/bin/env bash
set -euo pipefail
root="$CLIPBOARD_TEST_DIR"
if [[ "${1:-}" == "-db-path" ]]; then
    [[ "$2" == "$CLIPBOARD_TEST_DIR/isolated-cliphist.db" ]]
    shift 2
fi
case "$1" in
    list)
        if [[ "${CLIPBOARD_TEST_SLOW_LIST:-0}" == 1 ]]; then sleep 0.25; fi
        cat "$root/history.tsv"
        ;;
    wipe) : > "$root/history.tsv" ;;
    delete)
        declare -A removed=()
        while IFS= read -r id; do
            [[ -n "$id" ]] && removed["$id"]=1
        done
        next="$root/history.tsv.next"
        : > "$next"
        while IFS= read -r line; do
            id="${line%%$'\t'*}"
            if [[ -z "${removed[$id]+x}" ]]; then printf '%s\n' "$line" >> "$next"; fi
        done < "$root/history.tsv"
        mv "$next" "$root/history.tsv"
        ;;
    decode)
        if [[ "$2" == "slow" ]]; then sleep 0.25; fi
        cat "$root/payloads/$2"
        ;;
    *) exit 64 ;;
esac
)";
        const QByteArray copier = R"(#!/usr/bin/env bash
set -euo pipefail
root="$CLIPBOARD_TEST_DIR"
printf '%s\n' "$@" > "$root/copier-args"
cat > "$root/copied-payload"
)";
        QVERIFY(writeFile(m_cliphist, cliphist, QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner));
        QVERIFY(writeFile(m_copier, copier, QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner));
        qputenv("CLIPBOARD_TEST_DIR", m_data.toUtf8());
        qputenv("XDG_CACHE_HOME", QDir(m_data).filePath("cache").toUtf8());

        const QByteArray text = "line one\twith tab\nUnicode: caf\xc3\xa9 \xf0\x9f\x8c\x99";
        QVERIFY(writeFile(QDir(m_payloads).filePath("text"), text));
        const QByteArray uris = "copy\r\nfile:///tmp/missing%20file.txt\r\n";
        QVERIFY(writeFile(QDir(m_payloads).filePath("files"), uris));
        const QByteArray uriList = "file:///tmp/missing%20file.txt\r\n";
        QVERIFY(writeFile(QDir(m_payloads).filePath("uri-list"), uriList));
        const QByteArray opaque = QByteArray::fromHex("0001feff00ff42");
        QVERIFY(writeFile(QDir(m_payloads).filePath("opaque"), opaque));
        QImage image(8, 5, QImage::Format_ARGB32);
        image.fill(QColor("#5b84d6"));
        QVERIFY(image.save(QDir(m_payloads).filePath("image"), "PNG"));
    }

    void preservesNewestFirstCliphistOrder()
    {
        QVERIFY(writeFile(QDir(m_payloads).filePath("newest"), "newest payload"));
        QVERIFY(writeFile(QDir(m_payloads).filePath("middle"), "middle payload"));
        QVERIFY(writeFile(QDir(m_payloads).filePath("oldest"), "oldest payload"));
        QVERIFY(writeListing({{"newest", "newest preview"}, {"middle", "middle preview"}, {"oldest", "oldest preview"}}));
        ClipboardController shell;
        configure(shell, QDir(m_data).filePath("favorites-order"));
        shell.initialize();
        shell.refresh();
        QTRY_COMPARE_WITH_TIMEOUT(shell.historyModel()->rowCount(), 3, 3000);
        QCOMPARE(role(shell.historyModel(), 0, "key").toString(), "newest");
        QCOMPARE(role(shell.historyModel(), 1, "key").toString(), "middle");
        QCOMPARE(role(shell.historyModel(), 2, "key").toString(), "oldest");
    }

    void textSearchAndExactPayloads()
    {
        QVERIFY(writeListing({{"text", "text preview"}, {"files", "files preview"}, {"uri-list", "uri list preview"},
                              {"image", "image preview"}, {"opaque", "opaque preview"}}));
        ClipboardController shell;
        configure(shell, QDir(m_data).filePath("favorites-text"));
        shell.initialize();
        shell.refresh();
        QTRY_COMPARE_WITH_TIMEOUT(shell.historyModel()->rowCount(), 5, 5000);
        for (int row = 0; row < 5; ++row)
            QTRY_VERIFY_WITH_TIMEOUT(!role(shell.historyModel(), row, "loading").toBool(), 5000);
        QCOMPARE(role(shell.historyModel(), 0, "key").toString(), "text");
        QVERIFY(role(shell.historyModel(), 0, "searchableText").toString().contains("Unicode: café 🌙"));
        QVERIFY(role(shell.historyModel(), 0, "searchableText").toString().contains("with tab"));
        QCOMPARE(role(shell.historyModel(), 1, "payloadKind").toString(), "files");
        QCOMPARE(role(shell.historyModel(), 1, "mimeType").toString(), "x-special/gnome-copied-files");
        QVERIFY(role(shell.historyModel(), 1, "previewText").toString().contains("missing file.txt"));
        QCOMPARE(role(shell.historyModel(), 2, "payloadKind").toString(), "files");
        QCOMPARE(role(shell.historyModel(), 2, "mimeType").toString(), "text/uri-list");
        QCOMPARE(role(shell.historyModel(), 3, "payloadKind").toString(), "image");
        QVERIFY(!role(shell.historyModel(), 3, "thumbnailUrl").toString().isEmpty());
        QCOMPARE(role(shell.historyModel(), 4, "mimeType").toString(), "application/octet-stream");

        struct CopyFixture {
            QString key;
            QByteArray bytes;
            QByteArray mimeType;
        };
        const QList<CopyFixture> payloads{{"text", "line one\twith tab\nUnicode: caf\xc3\xa9 \xf0\x9f\x8c\x99", "text/plain;charset=utf-8"},
                                           {"files", "copy\r\nfile:///tmp/missing%20file.txt\r\n", "x-special/gnome-copied-files"},
                                           {"uri-list", "file:///tmp/missing%20file.txt\r\n", "text/uri-list"},
                                           {"opaque", QByteArray::fromHex("0001feff00ff42"), "application/octet-stream"}};
        QSignalSpy copySpy(&shell, &ClipboardController::copyCompleted);
        for (const auto &payload : payloads) {
            QFile::remove(QDir(m_data).filePath("copied-payload"));
            shell.copyEntry(payload.key);
            QTRY_VERIFY_WITH_TIMEOUT(QFileInfo::exists(QDir(m_data).filePath("copied-payload")), 3000);
            QFile copied(QDir(m_data).filePath("copied-payload"));
            QVERIFY(copied.open(QIODevice::ReadOnly));
            QCOMPARE(copied.readAll(), payload.bytes);
            QFile copierArgs(QDir(m_data).filePath("copier-args"));
            QVERIFY(copierArgs.open(QIODevice::ReadOnly));
            const QList<QByteArray> args = copierArgs.readAll().split('\n');
            QCOMPARE(args.value(0), QByteArray("--type"));
            QCOMPARE(args.value(1), payload.mimeType);
            QTRY_COMPARE_WITH_TIMEOUT(copySpy.count(), 1, 3000);
            QVERIFY(copySpy.takeFirst().at(1).toBool());
        }
        QFile::remove(QDir(m_data).filePath("copied-payload"));
        shell.copyEntry("image");
        QTRY_VERIFY_WITH_TIMEOUT(QFileInfo::exists(QDir(m_data).filePath("copied-payload")), 3000);
        QTRY_COMPARE_WITH_TIMEOUT(copySpy.count(), 1, 3000);
        QVERIFY(copySpy.takeFirst().at(1).toBool());
        QFile original(QDir(m_payloads).filePath("image"));
        QFile copied(QDir(m_data).filePath("copied-payload"));
        QVERIFY(original.open(QIODevice::ReadOnly));
        QVERIFY(copied.open(QIODevice::ReadOnly));
        QCOMPARE(copied.readAll(), original.readAll());
        QFile copierArgs(QDir(m_data).filePath("copier-args"));
        QVERIFY(copierArgs.open(QIODevice::ReadOnly));
        QCOMPARE(copierArgs.readAll().split('\n').value(1), QByteArray("image/png"));
    }

    void favoriteIdentityOrderEvictionAndReload()
    {
        const QString favoriteDirectory = QDir(m_data).filePath("favorites-persistence");
        QVERIFY(writeListing({{"text", "text"}, {"opaque", "opaque"}}));
        QString expectedFirst;
        {
            ClipboardController shell;
            configure(shell, favoriteDirectory);
            shell.initialize();
            shell.refresh();
            QTRY_COMPARE_WITH_TIMEOUT(shell.historyModel()->rowCount(), 2, 3000);
            QTRY_VERIFY_WITH_TIMEOUT(!role(shell.historyModel(), 0, "loading").toBool(), 5000);
            QTRY_VERIFY_WITH_TIMEOUT(!role(shell.historyModel(), 1, "loading").toBool(), 5000);
            shell.setFavorite("text", true);
            shell.setFavorite("opaque", true);
            QTRY_COMPARE_WITH_TIMEOUT(shell.favoritesModel()->rowCount(), 2, 3000);
            const QString firstHash = role(shell.favoritesModel(), 0, "key").toString();
            const QString secondHash = role(shell.favoritesModel(), 1, "key").toString();
            shell.setFavorite("opaque", false);
            QTRY_COMPARE_WITH_TIMEOUT(shell.favoritesModel()->rowCount(), 1, 3000);
            QVERIFY(!role(shell.historyModel(), 1, "favorite").toBool());
            shell.setFavorite("opaque", true);
            QTRY_COMPARE_WITH_TIMEOUT(shell.favoritesModel()->rowCount(), 2, 3000);
            shell.moveFavorite(secondHash, firstHash);
            QTRY_COMPARE_WITH_TIMEOUT(role(shell.favoritesModel(), 0, "key").toString(), secondHash, 3000);
            expectedFirst = secondHash;
            QVERIFY(writeFile(QDir(m_payloads).filePath("recopied"), "line one\twith tab\nUnicode: caf\xc3\xa9 \xf0\x9f\x8c\x99"));
            QVERIFY(writeListing({{"recopied", "same content under a new history id"}}));
            shell.refresh();
            QTRY_COMPARE_WITH_TIMEOUT(shell.historyModel()->rowCount(), 1, 3000);
            QTRY_VERIFY_WITH_TIMEOUT(role(shell.historyModel(), 0, "favorite").toBool(), 5000);
            QVERIFY(writeListing({}));
            shell.refresh();
            QTRY_COMPARE_WITH_TIMEOUT(shell.historyModel()->rowCount(), 0, 3000);
            QCOMPARE(shell.favoritesModel()->rowCount(), 2);
        }
        {
            ClipboardController restored;
            configure(restored, favoriteDirectory);
            restored.initialize();
            QTRY_COMPARE_WITH_TIMEOUT(restored.favoritesModel()->rowCount(), 2, 3000);
            QTRY_VERIFY_WITH_TIMEOUT(!role(restored.favoritesModel(), 0, "loading").toBool(), 5000);
            QCOMPARE(role(restored.favoritesModel(), 0, "key").toString(), expectedFirst);
            QVERIFY(QFileInfo(QDir(favoriteDirectory).filePath("favorites.json")).permissions() & QFileDevice::ReadOwner);
        }
    }

    void clearActionsTargetTheActiveCollection()
    {
        const QString favoriteDirectory = QDir(m_data).filePath("favorites-clear-actions");
        QVERIFY(writeListing({{"text", "text preview"}}));
        ClipboardController shell;
        configure(shell, favoriteDirectory);
        shell.initialize();
        shell.refresh();
        QTRY_COMPARE_WITH_TIMEOUT(shell.historyModel()->rowCount(), 1, 3000);
        QTRY_VERIFY_WITH_TIMEOUT(!role(shell.historyModel(), 0, "loading").toBool(), 5000);
        shell.setFavorite("text", true);
        QTRY_COMPARE_WITH_TIMEOUT(shell.favoritesModel()->rowCount(), 1, 3000);

        QVERIFY(shell.clearFavorites());
        QCOMPARE(shell.favoritesModel()->rowCount(), 0);
        QCOMPARE(shell.historyModel()->rowCount(), 1);
        QVERIFY(!role(shell.historyModel(), 0, "favorite").toBool());

        shell.setFavorite("text", true);
        QTRY_COMPARE_WITH_TIMEOUT(shell.favoritesModel()->rowCount(), 1, 3000);
        QSignalSpy clearSpy(&shell, &ClipboardController::historyClearCompleted);
        qputenv("CLIPBOARD_TEST_SLOW_LIST", "1");
        shell.refresh();
        QVERIFY(shell.loading());
        shell.clearHistory();
        QTRY_COMPARE_WITH_TIMEOUT(clearSpy.count(), 1, 3000);
        qunsetenv("CLIPBOARD_TEST_SLOW_LIST");
        QVERIFY(clearSpy.takeFirst().at(0).toBool());
        QTRY_COMPARE_WITH_TIMEOUT(shell.historyModel()->rowCount(), 0, 3000);
        QCOMPARE(shell.favoritesModel()->rowCount(), 1);
        QFile listing(m_list);
        QVERIFY(listing.open(QIODevice::ReadOnly));
        QVERIFY(listing.readAll().isEmpty());
    }

    void clearFailuresAreReportedWithoutChangingSavedData()
    {
        QVERIFY(writeListing({{"text", "text preview"}}));
        ClipboardController missing;
        configure(missing, QDir(m_data).filePath("favorites-clear-missing-tool"));
        missing.setCliphistPath(QDir(m_data).filePath("missing-cliphist"));
        QSignalSpy clearSpy(&missing, &ClipboardController::historyClearCompleted);
        missing.clearHistory();
        QTRY_COMPARE_WITH_TIMEOUT(clearSpy.count(), 1, 3000);
        const QList<QVariant> clearResult = clearSpy.takeFirst();
        QVERIFY(!clearResult.at(0).toBool());
        QVERIFY(!clearResult.at(1).toString().isEmpty());
        QVERIFY(!missing.clearingHistory());
        QFile listing(m_list);
        QVERIFY(listing.open(QIODevice::ReadOnly));
        QVERIFY(!listing.readAll().isEmpty());

        const QString source = QDir(m_data).filePath("clear-failure-payload");
        const QByteArray bytes = "keep this favorite";
        QVERIFY(writeFile(source, bytes));
        const QString hash = QString::fromLatin1(QCryptographicHash::hash(bytes, QCryptographicHash::Sha256).toHex());
        const QString favoriteDirectory = QDir(m_data).filePath("favorites-clear-write-failure");
        FavoritesStore store;
        store.setDirectory(favoriteDirectory);
        QString error;
        QVERIFY(store.load(&error));
        QVERIFY(store.add(hash, source, &error));
        const QString manifest = QDir(favoriteDirectory).filePath("favorites.json");
        QVERIFY(QFile::remove(manifest));
        QVERIFY(QDir().mkpath(manifest));
        QVERIFY(!store.clear(&error));
        QCOMPARE(store.hashes(), QStringList{hash});
        QVERIFY(QFileInfo::exists(store.payloadPath(hash)));
        QVERIFY(!error.isEmpty());
    }

    void entryDeletionTargetsTheRequestedCollection()
    {
        const QString favoriteDirectory = QDir(m_data).filePath("favorites-entry-delete");
        QVERIFY(writeListing({{"text", "text preview"}, {"opaque", "opaque preview"}}));
        ClipboardController favorites;
        configure(favorites, favoriteDirectory);
        favorites.initialize();
        favorites.refresh();
        QTRY_COMPARE_WITH_TIMEOUT(favorites.historyModel()->rowCount(), 2, 3000);
        QTRY_VERIFY_WITH_TIMEOUT(!role(favorites.historyModel(), 0, "loading").toBool(), 5000);
        QTRY_VERIFY_WITH_TIMEOUT(!role(favorites.historyModel(), 1, "loading").toBool(), 5000);
        favorites.setFavorite("text", true);
        QTRY_COMPARE_WITH_TIMEOUT(favorites.favoritesModel()->rowCount(), 1, 3000);
        QTRY_VERIFY_WITH_TIMEOUT(!role(favorites.favoritesModel(), 0, "loading").toBool(), 5000);

        const QString favoriteHash = role(favorites.favoritesModel(), 0, "key").toString();
        QSignalSpy favoriteDeleteSpy(&favorites, &ClipboardController::entryDeleteCompleted);
        favorites.deleteFavoriteEntry(favoriteHash);
        QTRY_COMPARE_WITH_TIMEOUT(favoriteDeleteSpy.count(), 1, 5000);
        const QList<QVariant> favoriteDelete = favoriteDeleteSpy.takeFirst();
        QVERIFY(favoriteDelete.at(1).toBool());
        QVERIFY(favoriteDelete.at(2).toBool());
        QTRY_COMPARE_WITH_TIMEOUT(favorites.favoritesModel()->rowCount(), 0, 3000);
        QTRY_COMPARE_WITH_TIMEOUT(favorites.historyModel()->rowCount(), 1, 5000);
        QCOMPARE(role(favorites.historyModel(), 0, "key").toString(), "opaque");

        QVERIFY(writeListing({{"text", "text preview"}, {"opaque", "opaque preview"}}));
        ClipboardController history;
        configure(history, QDir(m_data).filePath("history-entry-delete"));
        history.initialize();
        history.refresh();
        QTRY_COMPARE_WITH_TIMEOUT(history.historyModel()->rowCount(), 2, 3000);
        QSignalSpy historyDeleteSpy(&history, &ClipboardController::entryDeleteCompleted);
        history.deleteHistoryEntry("opaque");
        QTRY_COMPARE_WITH_TIMEOUT(historyDeleteSpy.count(), 1, 5000);
        const QList<QVariant> historyDelete = historyDeleteSpy.takeFirst();
        QVERIFY(!historyDelete.at(1).toBool());
        QVERIFY(historyDelete.at(2).toBool());
        QTRY_COMPARE_WITH_TIMEOUT(history.historyModel()->rowCount(), 1, 5000);
        QCOMPARE(role(history.historyModel(), 0, "key").toString(), "text");
    }

    void deletionFailurePreservesHistoryAndFavorite()
    {
        QVERIFY(writeListing({{"text", "text preview"}}));
        const QString favoriteDirectory = QDir(m_data).filePath("favorites-entry-delete-failure");
        ClipboardController shell;
        configure(shell, favoriteDirectory);
        shell.initialize();
        shell.refresh();
        QTRY_COMPARE_WITH_TIMEOUT(shell.historyModel()->rowCount(), 1, 3000);
        QTRY_VERIFY_WITH_TIMEOUT(!role(shell.historyModel(), 0, "loading").toBool(), 5000);
        shell.setFavorite("text", true);
        QTRY_COMPARE_WITH_TIMEOUT(shell.favoritesModel()->rowCount(), 1, 3000);
        QTRY_VERIFY_WITH_TIMEOUT(!role(shell.favoritesModel(), 0, "loading").toBool(), 5000);

        const QString favoriteHash = role(shell.favoritesModel(), 0, "key").toString();
        const QString missingTool = QDir(m_data).filePath("missing-cliphist-for-delete");
        QVERIFY(!QFileInfo::exists(missingTool));
        shell.setCliphistPath(missingTool);
        QSignalSpy deleteSpy(&shell, &ClipboardController::entryDeleteCompleted);
        shell.deleteFavoriteEntry(favoriteHash);
        QTRY_COMPARE_WITH_TIMEOUT(deleteSpy.count(), 1, 5000);
        const QList<QVariant> result = deleteSpy.takeFirst();
        QVERIFY(!result.at(2).toBool());
        QVERIFY(!result.at(3).toString().isEmpty());
        QCOMPARE(shell.historyModel()->rowCount(), 1);
        QCOMPARE(shell.favoritesModel()->rowCount(), 1);
        QVERIFY(QFileInfo::exists(QDir(favoriteDirectory).filePath(favoriteHash + ".payload")));
    }

    void evictionReleasesHistoryPayloadFile()
    {
        const QStringList existingDirectories = QDir(QDir::tempPath()).entryList(
            {"caelestia-clipboard-*"}, QDir::Dirs | QDir::NoDotAndDotDot);
        QVERIFY(writeListing({{"text", "temporary payload"}}));
        ClipboardController shell;
        configure(shell, QDir(m_data).filePath("favorites-payload-cleanup"));
        shell.initialize();
        shell.refresh();
        QTRY_COMPARE_WITH_TIMEOUT(shell.historyModel()->rowCount(), 1, 3000);
        QTRY_VERIFY_WITH_TIMEOUT(!role(shell.historyModel(), 0, "loading").toBool(), 5000);

        QString temporaryDirectory;
        for (const auto &directory : QDir(QDir::tempPath()).entryList(
                 {"caelestia-clipboard-*"}, QDir::Dirs | QDir::NoDotAndDotDot)) {
            if (!existingDirectories.contains(directory))
                temporaryDirectory = QDir(QDir::tempPath()).filePath(directory);
        }
        QVERIFY(!temporaryDirectory.isEmpty());
        QCOMPARE(QDir(temporaryDirectory).entryList({"payload-*"}, QDir::Files).size(), 1);

        QVERIFY(writeListing({}));
        shell.refresh();
        QTRY_COMPARE_WITH_TIMEOUT(shell.historyModel()->rowCount(), 0, 3000);
        QTRY_VERIFY_WITH_TIMEOUT(QDir(temporaryDirectory).entryList({"payload-*"}, QDir::Files).isEmpty(), 3000);
    }

    void corruptStoreMissingToolsVanishedRowsAndStaleDecode()
    {
        const QString corruptDirectory = QDir(m_data).filePath("favorites-corrupt");
        QVERIFY(QDir().mkpath(corruptDirectory));
        const QString manifest = QDir(corruptDirectory).filePath("favorites.json");
        QVERIFY(writeFile(manifest, "{broken"));
        ClipboardController corrupt;
        configure(corrupt, corruptDirectory);
        corrupt.initialize();
        corrupt.refresh();
        QTRY_VERIFY_WITH_TIMEOUT(!corrupt.loading(), 5000);
        QVERIFY(!corrupt.errorMessage().isEmpty());
        QFile before(manifest);
        QVERIFY(before.open(QIODevice::ReadOnly));
        const QByteArray originalManifest = before.readAll();
        corrupt.setFavorite("text", true);
        QFile after(manifest);
        QVERIFY(after.open(QIODevice::ReadOnly));
        QCOMPARE(after.readAll(), originalManifest);
        QVERIFY(!corrupt.errorMessage().isEmpty());

        ClipboardController missing;
        configure(missing, QDir(m_data).filePath("favorites-missing-tool"));
        missing.setCliphistPath(QDir(m_data).filePath("does-not-exist"));
        missing.initialize();
        missing.refresh();
        QTRY_VERIFY_WITH_TIMEOUT(!missing.loading(), 3000);
        QVERIFY(!missing.errorMessage().isEmpty());

        ClipboardController copyFailure;
        configure(copyFailure, QDir(m_data).filePath("favorites-copy-failure"));
        copyFailure.setWlCopyPath(QDir(m_data).filePath("missing-wl-copy"));
        QVERIFY(writeListing({{"text", "copy failure"}}));
        copyFailure.initialize();
        copyFailure.refresh();
        QTRY_COMPARE_WITH_TIMEOUT(copyFailure.historyModel()->rowCount(), 1, 3000);
        QTRY_VERIFY_WITH_TIMEOUT(!role(copyFailure.historyModel(), 0, "loading").toBool(), 5000);
        QSignalSpy copySpy(&copyFailure, &ClipboardController::copyCompleted);
        copyFailure.copyEntry("text");
        QTRY_COMPARE_WITH_TIMEOUT(copySpy.count(), 1, 3000);
        QVERIFY(!copySpy.takeFirst().at(1).toBool());
        QVERIFY(!copyFailure.errorMessage().isEmpty());

        QVERIFY(writeListing({{"vanished", "gone"}}));
        QFile::remove(QDir(m_payloads).filePath("vanished"));
        ClipboardController vanished;
        configure(vanished, QDir(m_data).filePath("favorites-vanished"));
        vanished.initialize();
        vanished.refresh();
        QTRY_COMPARE_WITH_TIMEOUT(vanished.historyModel()->rowCount(), 1, 3000);
        QTRY_VERIFY_WITH_TIMEOUT(!role(vanished.historyModel(), 0, "errorText").toString().isEmpty(), 3000);

        QVERIFY(writeFile(QDir(m_payloads).filePath("slow"), "stale data"));
        QVERIFY(writeFile(QDir(m_payloads).filePath("fresh"), "fresh data"));
        QVERIFY(writeListing({{"slow", "old"}}));
        ClipboardController stale;
        configure(stale, QDir(m_data).filePath("favorites-stale"));
        stale.initialize();
        stale.refresh();
        QTRY_COMPARE_WITH_TIMEOUT(stale.historyModel()->rowCount(), 1, 3000);
        QSignalSpy expiredCopySpy(&stale, &ClipboardController::copyCompleted);
        stale.copyEntry("slow");
        QVERIFY(writeListing({{"fresh", "current"}}));
        stale.refresh();
        QTRY_COMPARE_WITH_TIMEOUT(role(stale.historyModel(), 0, "key").toString(), "fresh", 3000);
        QTRY_COMPARE_WITH_TIMEOUT(expiredCopySpy.count(), 1, 3000);
        QVERIFY(!expiredCopySpy.takeFirst().at(1).toBool());
        QTest::qWait(500);
        QCOMPARE(role(stale.historyModel(), 0, "key").toString(), "fresh");
        QVERIFY(role(stale.historyModel(), 0, "searchableText").toString().contains("fresh data"));
    }

    void classifierAndAtomicFavorites()
    {
        const QString source = QDir(m_data).filePath("hash-source");
        const QByteArray bytes = "retained payload\twith tabs\n";
        QVERIFY(writeFile(source, bytes));
        const QString hash = QString::fromLatin1(QCryptographicHash::hash(bytes, QCryptographicHash::Sha256).toHex());
        FavoritesStore store;
        store.setDirectory(QDir(m_data).filePath("favorites-store"));
        QString error;
        QVERIFY(store.load(&error));
        QVERIFY(store.add(hash, source, &error));
        QCOMPARE(store.hashes(), QStringList{hash});
        QVERIFY(store.moveBefore(hash, hash, &error));
        const auto sharedPermissions = QFileDevice::ReadGroup | QFileDevice::WriteGroup | QFileDevice::ExeGroup
            | QFileDevice::ReadOther | QFileDevice::WriteOther | QFileDevice::ExeOther;
        QVERIFY(!(QFileInfo(store.payloadPath(hash)).permissions() & sharedPermissions));
        QVERIFY(!(QFileInfo(QDir(store.directory()).filePath("favorites.json")).permissions() & sharedPermissions));
        QVERIFY(!store.add(QString(64, 'a'), QDir(m_data).filePath("missing-payload"), &error));
        QCOMPARE(store.hashes(), QStringList{hash});
        QVERIFY(store.moveBefore(hash, {}, &error));
        QVERIFY(store.remove(hash, &error));
        QVERIFY(store.hashes().isEmpty());
        QVERIFY(!QFileInfo::exists(store.payloadPath(hash)));
        QVERIFY(store.add(hash, source, &error));
        const QString orphanPayload = QDir(store.directory()).filePath(QString(64, 'b') + ".payload");
        QVERIFY(writeFile(orphanPayload, "orphaned payload"));
        QVERIFY(store.clear(&error));
        QVERIFY(store.hashes().isEmpty());
        QVERIFY(!QFileInfo::exists(store.payloadPath(hash)));
        QVERIFY(!QFileInfo::exists(orphanPayload));

        const QString failedDirectory = QDir(m_data).filePath("favorites-failed-write");
        FavoritesStore failedStore;
        failedStore.setDirectory(failedDirectory);
        QVERIFY(failedStore.load(&error));
        QVERIFY(QDir().mkpath(QDir(failedDirectory).filePath("favorites.json")));
        QVERIFY(!failedStore.add(hash, source, &error));
        QVERIFY(!error.isEmpty());
        QVERIFY(failedStore.hashes().isEmpty());

        const QString corruptDirectory = QDir(m_data).filePath("favorites-corrupt-payload");
        FavoritesStore savedStore;
        savedStore.setDirectory(corruptDirectory);
        QVERIFY(savedStore.load(&error));
        QVERIFY(savedStore.add(hash, source, &error));
        const QString manifestPath = QDir(corruptDirectory).filePath("favorites.json");
        QFile manifestBeforeFile(manifestPath);
        QVERIFY(manifestBeforeFile.open(QIODevice::ReadOnly));
        const QByteArray manifestBefore = manifestBeforeFile.readAll();
        QVERIFY(writeFile(savedStore.payloadPath(hash), "changed bytes"));
        ClipboardController corruptedFavorite;
        configure(corruptedFavorite, corruptDirectory);
        corruptedFavorite.initialize();
        QTRY_COMPARE_WITH_TIMEOUT(corruptedFavorite.favoritesModel()->rowCount(), 1, 3000);
        QTRY_VERIFY_WITH_TIMEOUT(!role(corruptedFavorite.favoritesModel(), 0, "loading").toBool(), 5000);
        QVERIFY(role(corruptedFavorite.favoritesModel(), 0, "errorText").toString().contains("content hash"));
        QVERIFY(corruptedFavorite.errorMessage().contains("content hash"));
        QSignalSpy corruptedCopySpy(&corruptedFavorite, &ClipboardController::copyCompleted);
        corruptedFavorite.copyEntry(hash);
        QTRY_COMPARE_WITH_TIMEOUT(corruptedCopySpy.count(), 1, 3000);
        QVERIFY(!corruptedCopySpy.takeFirst().at(1).toBool());
        QFile manifestAfterFile(manifestPath);
        QVERIFY(manifestAfterFile.open(QIODevice::ReadOnly));
        QCOMPARE(manifestAfterFile.readAll(), manifestBefore);

        const PayloadDescription description = PayloadClassifier::inspect(source, QDir(m_data).filePath("thumbs"));
        QCOMPARE(description.payloadKind, "text");
        QCOMPARE(description.mimeType, "text/plain;charset=utf-8");
        QCOMPARE(description.size, bytes.size());

        const QString invalidText = QDir(m_data).filePath("invalid-utf8");
        QVERIFY(writeFile(invalidText, QByteArray::fromHex("616263f0")));
        const PayloadDescription invalidDescription = PayloadClassifier::inspect(invalidText, QDir(m_data).filePath("thumbs"));
        QCOMPARE(invalidDescription.payloadKind, "binary");
        QCOMPARE(invalidDescription.mimeType, "application/octet-stream");

        QByteArray largeText(8 * 1024 * 1024 + 128, 'a');
        largeText.replace(1024 * 1024 - 2, 4, QByteArray::fromHex("f09f8c99"));
        const QByteArray tail = "full-text-tail-marker";
        largeText.replace(largeText.size() - tail.size(), tail.size(), tail);
        const QString largeSource = QDir(m_data).filePath("large-text");
        QVERIFY(writeFile(largeSource, largeText));
        const PayloadDescription largeDescription = PayloadClassifier::inspect(largeSource, QDir(m_data).filePath("thumbs"));
        QCOMPARE(largeDescription.payloadKind, "text");
        QCOMPARE(largeDescription.size, largeText.size());
        QCOMPARE(largeDescription.contentHash.size(), 64);
        QVERIFY(largeDescription.searchableText.contains("🌙"));
        QVERIFY(largeDescription.searchableText.contains("full-text-tail-marker"));
        QVERIFY(largeDescription.previewText.size() <= 52);
        QVERIFY(largeDescription.previewText.endsWith("…"));
        QVERIFY(!largeDescription.previewText.contains("full-text-tail-marker"));

        const QString multilineSource = QDir(m_data).filePath("multiline-preview");
        QVERIFY(writeFile(multilineSource, "first line\nsecond line\nthird line\nfourth searchable tail"));
        const PayloadDescription multiline = PayloadClassifier::inspect(multilineSource, QDir(m_data).filePath("thumbs"));
        QCOMPARE(multiline.previewText.count('\n'), 2);
        QVERIFY(multiline.previewText.endsWith("…"));
        QVERIFY(multiline.searchableText.contains("fourth searchable tail"));
    }

    void richTextClassificationAndPreview()
    {
        const QString path = QDir(m_data).filePath("rich-preview");
        const QString thumbs = QDir(m_data).filePath("rich-thumbnails");
        const QList<QPair<QByteArray, QString>> cases = {
            {"https://example.com/path?q=1", "link"},
            {"file:///tmp/example.txt", "files"},
            {"#7aa2f7", "color"},
            {"{\"name\": \"clipboard\", \"count\": 2}", "json"},
            {"function pasteEntry(id) {\n  return id;\n}", "code"},
            {"The quick brown fox\nfull preview tail", "text"},
            {"prefix https://example.com/ is prose", "text"},
            {"{invalid json}", "text"}
        };
        for (const auto &test : cases) {
            QVERIFY(writeFile(path, test.first));
            const auto description = PayloadClassifier::inspect(path, thumbs);
            QCOMPARE(description.payloadKind, test.second);
            QCOMPARE(description.contentText, QString::fromUtf8(test.first));
        }
        QVERIFY(writeFile(path, QByteArray(140 * 1024, 'x')));
        const auto bounded = PayloadClassifier::inspect(path, thumbs);
        QVERIFY(bounded.contentText.size() < 129 * 1024);
        QVERIFY(bounded.contentText.endsWith("copying preserves the full payload."));
        QCOMPARE(bounded.size, 140 * 1024);
    }

    void qrImagePreview()
    {
        const QString encoder = QStandardPaths::findExecutable("qrencode");
        if (encoder.isEmpty())
            QSKIP("qrencode is not available for the QR fixture");
        const QString path = QDir(m_data).filePath("qr-preview.png");
        QProcess process;
        process.start(encoder, {"-o", path, "https://example.com/clipboard-qr"});
        QVERIFY(process.waitForFinished(3000));
        QCOMPARE(process.exitCode(), 0);
        const auto description = PayloadClassifier::inspect(path, QDir(m_data).filePath("qr-thumbnails"));
        QCOMPARE(description.payloadKind, "image");
        QVERIFY(!description.imageUrl.isEmpty());
#ifdef CLIPBOARD_TEST_HAS_ZXING
        QCOMPARE(description.qrText, "https://example.com/clipboard-qr");
        QVERIFY(description.searchableText.contains(description.qrText));
#endif
    }

    void filterRetainsSourceOrderAndMatchesDecodedText()
    {
        ClipboardListModel source(false);
        ClipboardEntry newest;
        newest.key = "newest";
        newest.searchableText = "URL https://example.com/clip";
        newest.payloadKind = "link";
        ClipboardEntry older;
        older.key = "older";
        older.searchableText = "Unicode string: café";
        older.payloadKind = "text";
        older.contentText = "Unicode string: café";
        source.replace({newest, older});
        ClipboardFilterModel filtered;
        filtered.setSourceModel(&source);
        filtered.setQuery("CAFÉ");
        QCOMPARE(filtered.rowCount(), 1);
        QCOMPARE(filtered.keyAt(0), "older");
        filtered.setQuery("");
        QCOMPARE(filtered.rowCount(), 2);
        QCOMPARE(filtered.keyAt(0), "newest");
        filtered.setKind("text");
        QCOMPARE(filtered.count(), 1);
        QCOMPARE(filtered.keyAt(0), "older");
        QCOMPARE(filtered.entryAt(0).value("contentText").toString(), older.contentText);
        QVERIFY(filtered.entryAt(-1).isEmpty());
        QVERIFY(filtered.entryAt(1).isEmpty());
        filtered.setQuery("example");
        QCOMPARE(filtered.count(), 0);
        filtered.setKind("link");
        QCOMPARE(filtered.count(), 1);
        QCOMPARE(filtered.keyAt(0), "newest");
        newest.payloadKind = "text";
        source.upsert(newest);
        QCOMPARE(filtered.count(), 0);
    }

    void copiedContentIdentitySurvivesNewHistoryKey()
    {
        const QByteArray payload = "Keep the selection attached to copied content";
        QVERIFY(writeFile(QDir(m_payloads).filePath("copy-before"), payload));
        QVERIFY(writeFile(QDir(m_payloads).filePath("copy-after"), payload));
        QVERIFY(writeFile(QDir(m_payloads).filePath("copy-other"), "Other entry"));
        QVERIFY(writeListing({{"copy-other", "Other entry"}, {"copy-before", "Copied entry"}}));
        ClipboardController shell;
        configure(shell, QDir(m_data).filePath("favorites-copy-identity"));
        shell.refresh();
        QTRY_VERIFY_WITH_TIMEOUT(!shell.loading(), 5000);
        ClipboardFilterModel filtered;
        filtered.setSourceModel(shell.historyModel());
        const QString hash = filtered.entryAt(1).value("contentHash").toString();
        QCOMPARE(hash, QString::fromLatin1(QCryptographicHash::hash(payload, QCryptographicHash::Sha256).toHex()));

        QSignalSpy copied(&shell, &ClipboardController::copyCompleted);
        shell.copyEntry("copy-before");
        QTRY_COMPARE_WITH_TIMEOUT(copied.count(), 1, 3000);
        QVERIFY(copied.at(0).at(1).toBool());
        bool publishedUndecoded = false;
        connect(shell.historyModel(), &QAbstractItemModel::rowsInserted, this,
                [&](const QModelIndex &, int first, int last) {
            for (int row = first; row <= last; ++row)
                publishedUndecoded |= role(shell.historyModel(), row, "loading").toBool();
        });
        QVERIFY(writeListing({{"copy-after", "Copied entry"}, {"copy-other", "Other entry"}}));
        shell.refresh();
        QTRY_VERIFY_WITH_TIMEOUT(!shell.loading(), 5000);
        QCOMPARE(filtered.keyAt(0), "copy-after");
        QCOMPARE(filtered.entryAt(0).value("contentHash").toString(), hash);
        QVERIFY(filtered.entryAt(1).value("contentHash").toString() != hash);
        QVERIFY(!publishedUndecoded);
    }

    void refreshPreservesStableRowsWithoutResettingModel()
    {
        ClipboardListModel model(false);
        QAbstractItemModelTester tester(&model, QAbstractItemModelTester::FailureReportingMode::QtTest);
        ClipboardEntry first;
        first.key = "first";
        first.previewText = "first preview";
        ClipboardEntry second;
        second.key = "second";
        second.previewText = "second preview";
        model.replace({first, second});

        QSignalSpy resetSpy(&model, &QAbstractItemModel::modelReset);
        model.replace({first, second});
        QCOMPARE(resetSpy.count(), 0);

        ClipboardEntry updatedSecond = second;
        updatedSecond.previewText = "updated preview";
        model.replace({updatedSecond, first});

        QCOMPARE(resetSpy.count(), 0);
        QCOMPARE(model.keyAt(0), "second");
        QCOMPARE(model.entry("second").previewText, "updated preview");
        QCOMPARE(model.keyAt(1), "first");

        model.replace({updatedSecond});
        QCOMPARE(resetSpy.count(), 0);
        QCOMPARE(model.rowCount(), 1);
        QCOMPARE(model.keyAt(0), "second");
    }
};

QTEST_GUILESS_MAIN(ClipboardTest)
#include "clipboard.moc"
