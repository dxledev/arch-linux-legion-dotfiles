#pragma once
#include <QHash>
#include <QString>

QString richTextFromMarkup(const QString &text, const QHash<QString, QString> &variables);
