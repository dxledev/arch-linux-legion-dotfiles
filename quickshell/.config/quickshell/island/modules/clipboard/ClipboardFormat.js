.pragma library

var kindIcons = {
    image: "image.svg",
    files: "folder.svg",
    link: "link.svg",
    code: "code.svg",
    json: "braces.svg",
    color: "palette.svg",
    binary: "binary.svg"
}

function kindIcon(kind) {
    return "../assets/icons/" + (kindIcons[kind] || "file-text.svg")
}

function bytes(size) {
    if (size < 1024)
        return size + " B"
    if (size < 1024 * 1024)
        return (size / 1024).toFixed(1) + " KiB"
    return (size / (1024 * 1024)).toFixed(1) + " MiB"
}

function details(kind, mime, size) {
    return (kind || "clipboard") + " · " + (mime || "type unknown") + " · " + bytes(size || 0)
}

function singleLine(text) {
    return String(text || "").replace(/[\r\n\t]+/g, " ")
}

function body(entry) {
    var text = entry.contentText || ""
    if (entry.payloadKind === "json") {
        try {
            return JSON.stringify(JSON.parse(text), null, 2)
        } catch (error) {
            return text
        }
    }
    return text || entry.previewText || ""
}

function link(entry) {
    var value = (entry.qrText || (entry.payloadKind === "link" ? entry.contentText : "") || "").trim()
    return /^https?:\/\/[^\s]+$/i.test(value) ? value : ""
}

function canReorder(query) {
    return String(query).trim().length === 0
}
