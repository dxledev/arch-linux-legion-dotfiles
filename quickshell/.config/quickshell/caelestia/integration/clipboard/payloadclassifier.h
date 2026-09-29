#pragma once

#include "clipboardentry.h"

#include <QString>

struct PayloadDescription
{
    QString previewText;
    QString searchableText;
    QString payloadKind;
    QString mimeType;
    QString thumbnailPath;
    QString contentHash;
    qint64 size = 0;
    QString errorText;
};

class PayloadClassifier final
{
public:
    static PayloadDescription inspect(const QString &payloadPath, const QString &thumbnailDirectory);
};
