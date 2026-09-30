#include "iconcolorization.h"

#include <algorithm>
#include <cmath>

namespace {
struct Levels {
    float minimum = 1;
    float maximum = 0;
    float sum = 0;
    float weight = 0;
};

float luminance(const uchar *pixel) {
    return (0.299F * pixel[0] + 0.587F * pixel[1] + 0.114F * pixel[2]) / 255;
}

float linearChannel(float value) {
    return value <= 0.04045F ? value / 12.92F : std::pow((value + 0.055F) / 1.055F, 2.4F);
}

float relativeLuminance(const QColor &tint) {
    return 0.2126F * linearChannel(tint.redF()) + 0.7152F * linearChannel(tint.greenF())
        + 0.0722F * linearChannel(tint.blueF());
}

Levels imageLevels(const QImage &image) {
    Levels levels;
    for (int y = 0; y < image.height(); ++y) {
        const auto *row = image.constScanLine(y);
        for (int x = 0; x < image.width(); ++x) {
            const auto *pixel = row + x * 4;
            if (pixel[3] < 8)
                continue;
            const float level = luminance(pixel);
            const float alpha = pixel[3] / 255.0F;
            levels.minimum = std::min(levels.minimum, level);
            levels.maximum = std::max(levels.maximum, level);
            levels.sum += level * alpha;
            levels.weight += alpha;
        }
    }
    return levels;
}

uchar channel(float value) {
    return static_cast<uchar>(std::lround(std::clamp(value, 0.0F, 1.0F) * 255));
}

void applyTint(QImage &image, const QColor &tint, const Levels &levels, bool light) {
    const float mean = levels.sum / levels.weight;
    const float tintLevel = relativeLuminance(tint);
    const bool invert = (tintLevel < 0.45F && mean > 0.55F) || (tintLevel > 0.55F && mean < 0.45F);
    const float rawSpan = levels.maximum - levels.minimum;
    const float padding = std::max(rawSpan, 0.001F) * 0.04F;
    const float minimum = std::max(0.0F, levels.minimum - padding);
    const float span = std::max(levels.maximum + padding - minimum, 0.001F);
    const float floor = light ? 0.32F : 0.28F;
    for (int y = 0; y < image.height(); ++y) {
        auto *row = image.scanLine(y);
        for (int x = 0; x < image.width(); ++x) {
            auto *pixel = row + x * 4;
            if (pixel[3] < 8)
                continue;
            float level = luminance(pixel);
            if (rawSpan >= 0.12F)
                level = std::clamp((level - minimum) / span, 0.0F, 1.0F);
            if (invert)
                level = 1 - level;
            const float display = floor + (1 - floor) * level;
            pixel[0] = channel(tint.redF() * display);
            pixel[1] = channel(tint.greenF() * display);
            pixel[2] = channel(tint.blueF() * display);
        }
    }
}
}

QImage boundedIconImage(const QImage &image) {
    const QImage bounded = image.width() > 256 || image.height() > 256
        ? image.scaled(256, 256, Qt::KeepAspectRatio, Qt::SmoothTransformation) : image;
    QImage result = bounded.convertToFormat(QImage::Format_RGBA8888);
    result.setDevicePixelRatio(1);
    return result;
}

QImage colorizeIcon(const QImage &image, const QColor &tint, bool light) {
    QImage result = boundedIconImage(image);
    const Levels levels = imageLevels(result);
    if (levels.weight > 0)
        applyTint(result, tint, levels, light);
    return result;
}
