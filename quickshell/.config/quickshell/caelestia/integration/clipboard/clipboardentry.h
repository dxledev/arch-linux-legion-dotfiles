#pragma once

#include <QString>

struct ClipboardEntry
{
    QString key;
    QString previewText;
    QString searchableText;
    QString payloadKind;
    QString mimeType;
    QString thumbnailUrl;
    QString contentHash;
    QString payloadPath;
    QString errorText;
    qint64 size = 0;
    bool favorite = false;
    bool loading = false;
    bool corrupted = false;
};
