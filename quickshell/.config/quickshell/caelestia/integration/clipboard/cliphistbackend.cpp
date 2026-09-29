#include "cliphistbackend.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QTemporaryFile>

CliphistBackend::CliphistBackend(QObject *parent)
    : QObject(parent), m_temporaryDirectory(QDir::tempPath() + "/caelestia-clipboard-XXXXXX")
{
    if (m_temporaryDirectory.isValid())
        QFile::setPermissions(m_temporaryDirectory.path(), QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner);
}

void CliphistBackend::setExecutable(QString executable)
{
    if (!executable.isEmpty())
        m_executable = std::move(executable);
}

void CliphistBackend::setCopyExecutable(QString executable)
{
    if (!executable.isEmpty())
        m_copyExecutable = std::move(executable);
}

void CliphistBackend::setDatabasePath(QString path)
{
    m_databasePath = std::move(path);
}

QString CliphistBackend::createPayloadPath()
{
    if (!m_temporaryDirectory.isValid())
        return {};
    QTemporaryFile file(QDir(m_temporaryDirectory.path()).filePath("payload-XXXXXX"));
    file.setAutoRemove(false);
    if (!file.open())
        return {};
    const QString path = file.fileName();
    file.close();
    QFile::setPermissions(path, QFileDevice::ReadOwner | QFileDevice::WriteOwner);
    return path;
}

QStringList CliphistBackend::arguments(const QStringList &command) const
{
    QStringList result;
    if (!m_databasePath.isEmpty())
        result << "-db-path" << m_databasePath;
    result.append(command);
    return result;
}

void CliphistBackend::refresh(quint64 generation)
{
    if (m_listing)
        return;
    m_listing = true;

    auto *process = new QProcess(this);
    const auto completeStartFailure = [this, process, generation](const QString &message) {
        if (!m_listing)
            return;
        m_listing = false;
        emit error(message);
        emit listingReady(generation, {}, {}, false);
        process->deleteLater();
    };
    connect(process, &QProcess::errorOccurred, this, [completeStartFailure, process](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart)
            completeStartFailure(process->errorString());
    });
    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this, process, generation](int code, QProcess::ExitStatus) {
        finishListing(process, generation, code);
    });
    process->start(m_executable, arguments({"list"}));
}

void CliphistBackend::wipe(quint64 request)
{
    auto *process = new QProcess(this);
    connect(process, &QProcess::errorOccurred, this, [this, process, request](QProcess::ProcessError error) {
        if (error != QProcess::FailedToStart)
            return;
        emit wipeFinished(request, false, process->errorString());
        process->deleteLater();
    });
    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this, process, request](int code, QProcess::ExitStatus) {
        const QString errorText = QString::fromLocal8Bit(process->readAllStandardError()).trimmed();
        emit wipeFinished(request, code == 0,
                          code == 0 ? QString() : errorText.isEmpty() ? "cliphist wipe failed." : errorText);
        process->deleteLater();
    });
    process->start(m_executable, arguments({"wipe"}));
}

void CliphistBackend::removeEntries(const QStringList &keys, quint64 request)
{
    QStringList validKeys;
    for (const auto &key : keys)
        if (!key.isEmpty())
            validKeys.append(key);
    if (validKeys.isEmpty()) {
        emit removeFinished(request, {}, false, "No clipboard history entry was selected.");
        return;
    }

    auto *process = new QProcess(this);
    process->setProperty("removeRequestCompleted", false);
    const auto complete = [this, process, request, validKeys](bool success, const QString &message) {
        if (process->property("removeRequestCompleted").toBool())
            return;
        process->setProperty("removeRequestCompleted", true);
        emit removeFinished(request, validKeys, success, message);
        process->deleteLater();
    };
    connect(process, &QProcess::started, this, [process, validKeys] {
        QByteArray input;
        for (const auto &key : validKeys)
            input += key.toUtf8() + '\n';
        process->write(input);
        process->closeWriteChannel();
    });
    connect(process, &QProcess::errorOccurred, this,
            [process, complete](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart)
            complete(false, process->errorString());
    });
    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [process, complete](int code, QProcess::ExitStatus) {
        const QString errorText = QString::fromLocal8Bit(process->readAllStandardError()).trimmed();
        complete(code == 0, code == 0 ? QString() : errorText.isEmpty() ? "cliphist delete failed." : errorText);
    });
    process->start(m_executable, arguments({"delete"}));
}

void CliphistBackend::finishListing(QProcess *process, quint64 generation, int exitCode)
{
    if (!m_listing)
        return;
    m_listing = false;
    const QByteArray output = process->readAllStandardOutput();
    const QString errorText = QString::fromLocal8Bit(process->readAllStandardError()).trimmed();
    QStringList keys;
    QStringList previews;
    if (exitCode == 0) {
        const QList<QByteArray> lines = output.split('\n');
        for (const QByteArray &line : lines) {
            const qsizetype separator = line.indexOf('\t');
            if (separator <= 0)
                continue;
            keys.append(QString::fromUtf8(line.first(separator)));
            previews.append(QString::fromUtf8(line.sliced(separator + 1)));
        }
    } else {
        emit error(errorText.isEmpty() ? "cliphist list failed." : errorText);
    }
    emit listingReady(generation, keys, previews, exitCode == 0);
    process->deleteLater();
}

void CliphistBackend::decode(const QString &key, quint64 generation, const QString &outputPath)
{
    auto *process = new QProcess(this);
    process->setStandardOutputFile(outputPath, QIODevice::Truncate);
    connect(process, &QProcess::errorOccurred, this, [this, process, key, generation, outputPath](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) {
            emit decodeReady(key, generation, outputPath, process->errorString());
            process->deleteLater();
        }
    });
    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this, process, key, generation, outputPath](int code, QProcess::ExitStatus) {
        const QString errorText = QString::fromLocal8Bit(process->readAllStandardError()).trimmed();
        emit decodeReady(key, generation, outputPath,
                         code == 0 ? QString() : errorText.isEmpty() ? "cliphist decode failed." : errorText);
        process->deleteLater();
    });
    process->start(m_executable, arguments({"decode", key}));
}

void CliphistBackend::copy(const QString &key, const QString &payloadPath, const QString &mimeType, quint64 request)
{
    auto *process = new QProcess(this);
    process->setStandardInputFile(payloadPath);
    connect(process, &QProcess::errorOccurred, this, [this, process, key, request](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) {
            emit copyFinished(key, request, false, process->errorString());
            process->deleteLater();
        }
    });
    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this, process, key, request](int code, QProcess::ExitStatus) {
        const QString errorText = QString::fromLocal8Bit(process->readAllStandardError()).trimmed();
        emit copyFinished(key, request, code == 0,
                          code == 0 ? QString() : errorText.isEmpty() ? "wl-copy failed." : errorText);
        process->deleteLater();
    });
    process->start(m_copyExecutable, {"--type", mimeType});
}
