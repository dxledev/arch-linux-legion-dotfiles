#pragma once

#include <QColor>
#include <QImage>

QImage boundedIconImage(const QImage &image);
QImage colorizeIcon(const QImage &image, const QColor &tint, bool light);
