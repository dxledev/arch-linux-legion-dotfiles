.pragma library

function composite(foreground, background) {
    const alpha = foreground.a + background.a * (1 - foreground.a);
    if (alpha === 0)
        return Qt.rgba(0, 0, 0, 0);
    const backgroundWeight = background.a * (1 - foreground.a);
    return Qt.rgba((foreground.r * foreground.a + background.r * backgroundWeight) / alpha,
                   (foreground.g * foreground.a + background.g * backgroundWeight) / alpha,
                   (foreground.b * foreground.a + background.b * backgroundWeight) / alpha, alpha);
}

function linearChannel(value) {
    return value <= 0.04045 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4);
}

function luminance(colour) {
    return 0.2126 * linearChannel(colour.r) + 0.7152 * linearChannel(colour.g) + 0.0722 * linearChannel(colour.b);
}

function ratio(foreground, background) {
    const front = luminance(composite(foreground, background));
    const back = luminance(background);
    return (Math.max(front, back) + 0.05) / (Math.min(front, back) + 0.05);
}

function mix(first, second, amount) {
    return Qt.rgba(first.r + (second.r - first.r) * amount,
                   first.g + (second.g - first.g) * amount,
                   first.b + (second.b - first.b) * amount,
                   first.a + (second.a - first.a) * amount);
}

function ratioAcross(foreground, backgrounds) {
    if (!Array.isArray(backgrounds))
        return ratio(foreground, backgrounds);
    let minimum = 21;
    for (const background of backgrounds)
        minimum = Math.min(minimum, ratio(foreground, background));
    return minimum;
}

function toward(foreground, target, background, minimum) {
    let low = 0;
    let high = 1;
    for (let step = 0; step < 14; step++) {
        const middle = (low + high) / 2;
        if (ratioAcross(mix(foreground, target, middle), background) >= minimum)
            high = middle;
        else
            low = middle;
    }
    return mix(foreground, target, high);
}

function distance(first, second) {
    return (first.r - second.r) ** 2 + (first.g - second.g) ** 2 + (first.b - second.b) ** 2;
}

function neutralFor(backgrounds) {
    let best = Qt.rgba(0, 0, 0, 1);
    let bestRatio = ratioAcross(best, backgrounds);
    for (let value = 1; value <= 255; value++) {
        const candidate = Qt.rgba(value / 255, value / 255, value / 255, 1);
        const candidateRatio = ratioAcross(candidate, backgrounds);
        if (candidateRatio > bestRatio) {
            best = candidate;
            bestRatio = candidateRatio;
        }
    }
    return best;
}

function ensure(foreground, background, minimum) {
    if (ratioAcross(foreground, background) >= minimum)
        return foreground;

    // QColor properties round channels, so corrected colors need a small margin.
    minimum += 0.1;
    const opaque = Qt.rgba(foreground.r, foreground.g, foreground.b, 1);
    if (ratioAcross(opaque, background) >= minimum)
        return toward(foreground, opaque, background, minimum);

    const dark = Qt.rgba(0, 0, 0, 1);
    const light = Qt.rgba(1, 1, 1, 1);
    const darkRatio = ratioAcross(dark, background);
    const lightRatio = ratioAcross(light, background);
    if (darkRatio < minimum && lightRatio < minimum)
        return Array.isArray(background) ? neutralFor(background) : darkRatio > lightRatio ? dark : light;
    if (darkRatio < minimum)
        return toward(opaque, light, background, minimum);
    if (lightRatio < minimum)
        return toward(opaque, dark, background, minimum);

    const darkCandidate = toward(opaque, dark, background, minimum);
    const lightCandidate = toward(opaque, light, background, minimum);
    return distance(opaque, darkCandidate) < distance(opaque, lightCandidate) ? darkCandidate : lightCandidate;
}

function background(item, fallback) {
    const layers = [];
    for (let current = item; current; current = current.parent) {
        const colour = current.color;
        if (colour && typeof colour.r === "number" && colour.a > 0) {
            layers.push(colour);
            if (colour.a === 1)
                break;
        }
    }
    let result = Qt.rgba(fallback.r, fallback.g, fallback.b, 1);
    for (let index = layers.length - 1; index >= 0; index--)
        result = composite(layers[index], result);
    return result;
}
