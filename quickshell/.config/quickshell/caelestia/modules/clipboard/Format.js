function bytes(size) {
    if (size < 1024)
        return `${size} B`;
    if (size < 1024 * 1024)
        return `${(size / 1024).toFixed(1)} KiB`;
    return `${(size / (1024 * 1024)).toFixed(1)} MiB`;
}

function body(entry) {
    const text = entry.contentText || "";
    if (entry.payloadKind === "json") {
        try {
            return JSON.stringify(JSON.parse(text), null, 2);
        } catch (error) {
            return text;
        }
    }
    return text || entry.previewText || "";
}

function link(entry) {
    const value = (entry.qrText || (entry.payloadKind === "link" ? entry.contentText : "") || "").trim();
    return /^https?:\/\/[^\s]+$/i.test(value) ? value : "";
}
