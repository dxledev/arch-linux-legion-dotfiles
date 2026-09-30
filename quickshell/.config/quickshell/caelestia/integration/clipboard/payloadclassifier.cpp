#include "payloadclassifier.h"

#include <QCryptographicHash>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImage>
#include <QImageReader>
#include <QJsonDocument>
#include <QRegularExpression>
#include <QMimeDatabase>
#include <QMimeType>
#include <QSaveFile>
#include <QStringDecoder>
#include <QUrl>

#ifdef CLIPBOARD_HAS_ZXING
#include <ZXing/ReadBarcode.h>
#endif

namespace {
constexpr qint64 MaxBufferedPayloadBytes = 8 * 1024 * 1024;
constexpr qint64 MaxImagePixels = 64 * 1024 * 1024;
constexpr int ThumbnailExtent = 360;

void inspectImageContent(PayloadDescription &result, const QString &path)
{
    result.imageUrl = QUrl::fromLocalFile(path).toString();
#ifdef CLIPBOARD_HAS_ZXING
    QImageReader reader(path);
    reader.setScaledSize(reader.size().scaled(1600, 1600, Qt::KeepAspectRatio));
    const QImage image = reader.read().convertToFormat(QImage::Format_Grayscale8);
    if (image.isNull())
        return;
    const ZXing::ImageView view(image.constBits(), image.width(), image.height(), ZXing::ImageFormat::Lum, image.bytesPerLine());
    const auto barcode = ZXing::ReadBarcode(view, ZXing::ReaderOptions().setFormats(ZXing::BarcodeFormat::QRCode));
    if (barcode.isValid()) {
        result.qrText = QString::fromStdString(barcode.text());
        result.previewText = result.qrText.left(160);
        result.searchableText += "\nQR code\n" + result.qrText;
    }
#endif
}

QString textKind(const QString &text)
{
    const QString trimmed = text.trimmed();
    const QUrl url(trimmed);
    if ((url.scheme() == "http" || url.scheme() == "https") && !url.host().isEmpty()
        && !trimmed.contains(QRegularExpression("\\s")))
        return "link";
    if (QRegularExpression("^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})$").match(trimmed).hasMatch())
        return "color";
    if (trimmed.size() <= 1024 * 1024 && (trimmed.startsWith('{') || trimmed.startsWith('['))
        && !QJsonDocument::fromJson(trimmed.toUtf8()).isNull())
        return "json";
    if (QRegularExpression("(?:^|\\n)\\s*(?:#include\\s*[<\"]|(?:export\\s+)?(?:function|class|const|let|import|def|fn)\\s+\\w+|(?:int|void|auto)\\s+\\w+\\s*\\()").match(trimmed).hasMatch())
        return "code";
    return "text";
}

QString imageMime(const QByteArray &format)
{
    const QByteArray normalized = format.toLower();
    if (normalized == "jpg" || normalized == "jpeg") return "image/jpeg";
    if (normalized == "png") return "image/png";
    if (normalized == "webp") return "image/webp";
    if (normalized == "gif") return "image/gif";
    if (normalized == "bmp") return "image/bmp";
    if (normalized == "tif" || normalized == "tiff") return "image/tiff";
    if (normalized == "avif") return "image/avif";
    return "application/octet-stream";
}

QString saveThumbnail(const QString &thumbnailDirectory, const QString &contentHash, const QImage &image, QString *errorText)
{
    if (!QDir().mkpath(thumbnailDirectory)) {
        if (errorText) *errorText = "Could not create the private thumbnail directory.";
        return {};
    }
    const auto privatePermissions = QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner;
    if (!QFile::setPermissions(QFileInfo(thumbnailDirectory).absolutePath(), privatePermissions)
        || !QFile::setPermissions(thumbnailDirectory, privatePermissions)) {
        if (errorText) *errorText = "Could not set private permissions on the thumbnail directory.";
        return {};
    }
    const QString thumbnailPath = QDir(thumbnailDirectory).filePath(contentHash + ".png");
    QSaveFile thumbnail(thumbnailPath);
    thumbnail.setDirectWriteFallback(false);
    if (!thumbnail.open(QIODevice::WriteOnly)) {
        if (errorText) *errorText = thumbnail.errorString();
        return {};
    }
    if (!thumbnail.setPermissions(QFileDevice::ReadOwner | QFileDevice::WriteOwner)) {
        thumbnail.cancelWriting();
        if (errorText) *errorText = "Could not set private permissions on the thumbnail.";
        return {};
    }
    if (!image.save(&thumbnail, "PNG") || !thumbnail.commit()) {
        if (errorText) *errorText = thumbnail.errorString();
        return {};
    }
    return thumbnailPath;
}

QString displayFileList(const QStringList &paths)
{
    QStringList names;
    names.reserve(paths.size());
    for (const auto &path : paths) {
        const QUrl url(path);
        const QString value = url.isLocalFile() ? url.toLocalFile() : url.toString();
        const QString name = url.isLocalFile() ? QFileInfo(value).fileName() : url.fileName(QUrl::PrettyDecoded);
        names.append(name.isEmpty() ? value : name);
    }
    return names.join('\n');
}

QString boundedPreview(const QString &text)
{
    constexpr qsizetype MaximumLines = 3;
    constexpr qsizetype MaximumLineCharacters = 48;
    QStringList lines;
    qsizetype position = 0;
    bool truncated = false;

    while (position < text.size() && lines.size() < MaximumLines) {
        qsizetype lineEnd = text.indexOf('\n', position);
        if (lineEnd < 0)
            lineEnd = text.size();
        const qsizetype length = lineEnd - position;
        qsizetype shownLength = qMin(length, MaximumLineCharacters);
        if (shownLength > 0 && shownLength < length && text.at(position + shownLength - 1).isHighSurrogate())
            --shownLength;
        QString line = text.mid(position, shownLength);
        line.replace('\t', "    ");
        lines.append(line);
        if (shownLength < length) {
            truncated = true;
            break;
        }
        if (lineEnd == text.size()) {
            position = text.size();
            break;
        }
        position = lineEnd + 1;
    }
    truncated = truncated || position < text.size();
    if (truncated) {
        if (lines.size() < MaximumLines)
            lines.append("…");
        else
            lines.last() = "…";
    }
    return lines.join('\n');
}

bool gnomeCopiedFiles(const QString &text)
{
    const QString firstLine = text.section('\n', 0, 0).trimmed();
    return firstLine == "copy" || firstLine == "cut";
}

bool uriPayload(const QString &text, QStringList *uris)
{
    QStringList lines = text.split('\n', Qt::SkipEmptyParts);
    if (!lines.isEmpty() && (lines.first().trimmed() == "copy" || lines.first().trimmed() == "cut"))
        lines.removeFirst();
    if (lines.isEmpty())
        return false;
    for (const auto &line : lines) {
        const auto trimmed = line.trimmed();
        if (trimmed.startsWith('#'))
            continue;
        const QUrl url(trimmed);
        if (!url.isValid() || !url.isLocalFile())
            return false;
        uris->append(trimmed);
    }
    return !uris->isEmpty();
}

void classifyText(PayloadDescription &result, const QString &text)
{
    constexpr qsizetype PreviewLimit = 128 * 1024;
    result.contentText = text.left(PreviewLimit);
    if (text.size() > PreviewLimit)
        result.contentText += "\n… Preview truncated; copying preserves the full payload.";
    QStringList uris;
    if (uriPayload(text, &uris)) {
        result.payloadKind = "files";
        result.mimeType = gnomeCopiedFiles(text) ? "x-special/gnome-copied-files" : "text/uri-list";
        result.previewText = boundedPreview(displayFileList(uris));
        result.searchableText = text + "\n" + result.previewText + "\nfile reference";
        return;
    }
    result.payloadKind = textKind(text);
    result.mimeType = "text/plain;charset=utf-8";
    result.previewText = text.trimmed().isEmpty() ? "Empty text" : boundedPreview(text);
    result.searchableText = text + "\ntext plain " + result.payloadKind;
}
}

PayloadDescription PayloadClassifier::inspect(const QString &payloadPath, const QString &thumbnailDirectory)
{
    PayloadDescription result;
    QFile file(payloadPath);
    if (!file.open(QIODevice::ReadOnly)) {
        result.errorText = file.errorString();
        return result;
    }

    result.size = file.size();
    if (result.size < 0 || result.size > MaxBufferedPayloadBytes) {
        QCryptographicHash digest(QCryptographicHash::Sha256);
        QByteArray sample;
        bool complete = true;
        while (!file.atEnd()) {
            const QByteArray chunk = file.read(1024 * 1024);
            if (chunk.isEmpty() && file.error() != QFileDevice::NoError) {
                result.errorText = file.errorString();
                complete = false;
                break;
            }
            digest.addData(chunk);
            if (sample.size() < 65536)
                sample.append(chunk.first(65536 - sample.size()));
        }
        if (complete)
            result.contentHash = QString::fromLatin1(digest.result().toHex());
        const QMimeType detected = QMimeDatabase().mimeTypeForData(sample);
        result.mimeType = detected.isValid() && detected.name() != "application/octet-stream"
            && !detected.name().startsWith("text/")
            ? detected.name() : "application/octet-stream";
        result.payloadKind = result.mimeType.startsWith("image/") ? "image" : "binary";
        QImageReader reader(payloadPath);
        const QSize dimensions = reader.size();
        if (result.payloadKind == "image" && dimensions.isValid()
            && static_cast<qint64>(dimensions.width()) * dimensions.height() <= MaxImagePixels) {
            reader.setScaledSize(dimensions.scaled(ThumbnailExtent, ThumbnailExtent, Qt::KeepAspectRatio));
            const QImage image = reader.read();
            if (!image.isNull())
                result.thumbnailPath = saveThumbnail(thumbnailDirectory, result.contentHash, image, &result.errorText);
        }
        result.previewText = result.payloadKind == "image" && dimensions.isValid()
            ? result.thumbnailPath.isEmpty()
                ? QString("Image · %1 × %2 · thumbnail unavailable · %3 · %4 bytes")
                      .arg(dimensions.width()).arg(dimensions.height()).arg(result.mimeType).arg(result.size)
                : QString("Image · %1 × %2 · %3").arg(dimensions.width()).arg(dimensions.height()).arg(result.mimeType)
            : result.payloadKind == "image"
                ? QString("Image · thumbnail unavailable · %1 · %2 bytes").arg(result.mimeType).arg(result.size)
                : QString("%1 · %2 bytes").arg(result.mimeType).arg(result.size);
        result.searchableText = result.previewText;
        if (!result.errorText.isEmpty())
            result.searchableText += " " + result.errorText;
        if (result.payloadKind != "image" && result.errorText.isEmpty() && file.seek(0)) {
            QStringDecoder decoder(QStringDecoder::Utf8);
            QString text;
            bool readableText = true;
            while (!file.atEnd()) {
                const QByteArray chunk = file.read(1024 * 1024);
                if (chunk.isEmpty() && file.error() != QFileDevice::NoError) {
                    readableText = false;
                    break;
                }
                if (chunk.contains('\0')) {
                    readableText = false;
                    break;
                }
                const QString decodedChunk = decoder.decode(chunk);
                if (decoder.hasError()) {
                    readableText = false;
                    break;
                }
                text.append(decodedChunk);
            }
            const auto finalResult = decoder.finalize();
            if (readableText && finalResult.error == QStringConverter::FinalizeResultError::NoError
                && !decoder.hasError()) {
                classifyText(result, text);
                return result;
            }
        }
        if (result.payloadKind == "image" && !result.thumbnailPath.isEmpty())
            inspectImageContent(result, payloadPath);
        return result;
    }

    const QByteArray bytes = file.readAll();
    result.contentHash = QString::fromLatin1(QCryptographicHash::hash(bytes, QCryptographicHash::Sha256).toHex());

    QStringDecoder decoder(QStringDecoder::Utf8);
    const QString text = decoder(bytes);
    const auto finalResult = decoder.finalize();
    if (!decoder.hasError() && finalResult.error == QStringConverter::FinalizeResultError::NoError && !bytes.contains('\0')) {
        classifyText(result, text);
        return result;
    }

    QImageReader reader(payloadPath);
    const QSize dimensions = reader.size();
    const qint64 pixels = static_cast<qint64>(dimensions.width()) * dimensions.height();
    if (dimensions.isValid() && pixels <= MaxImagePixels) {
        const QByteArray format = reader.format();
        reader.setScaledSize(dimensions.scaled(ThumbnailExtent, ThumbnailExtent, Qt::KeepAspectRatio));
        QImage image = reader.read();
        if (!image.isNull()) {
            result.thumbnailPath = saveThumbnail(thumbnailDirectory, result.contentHash, image, &result.errorText);
            result.payloadKind = "image";
            result.mimeType = imageMime(format);
            if (result.mimeType == "application/octet-stream") {
                const QMimeType detected = QMimeDatabase().mimeTypeForData(bytes);
                if (detected.isValid() && detected.name().startsWith("image/"))
                    result.mimeType = detected.name();
            }
            result.previewText = QString("Image · %1 × %2 · %3").arg(dimensions.width()).arg(dimensions.height()).arg(result.mimeType);
            result.searchableText = result.previewText + " image " + result.mimeType;
            inspectImageContent(result, payloadPath);
            return result;
        }
    }

    const QMimeType detected = QMimeDatabase().mimeTypeForData(bytes);
    if (detected.isValid() && detected.name().startsWith("image/")) {
        result.payloadKind = "image";
        result.mimeType = detected.name();
        result.previewText = dimensions.isValid()
            ? QString("Image · %1 × %2 · thumbnail unavailable · %3 · %4 bytes")
                  .arg(dimensions.width()).arg(dimensions.height()).arg(result.mimeType).arg(result.size)
            : QString("Image · thumbnail unavailable · %1 · %2 bytes").arg(result.mimeType).arg(result.size);
        result.searchableText = result.previewText + " image " + result.mimeType;
        return result;
    }
    result.payloadKind = "binary";
    result.mimeType = detected.isValid() && detected.name() != "application/octet-stream"
        && !detected.name().startsWith("text/")
        ? detected.name() : "application/octet-stream";
    result.previewText = QString("%1 · %2 bytes").arg(result.mimeType).arg(result.size);
    result.searchableText = result.previewText + " binary " + result.mimeType;
    if (!result.errorText.isEmpty())
        result.searchableText += " " + result.errorText;
    return result;
}
