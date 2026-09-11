.pragma library

function titleCase(text) {
    return text.replace(/[-_]+/g, " ").replace(/\b(.)/g, character => character.toUpperCase());
}

function displayName(path) {
    const filename = path.split("/").pop();
    const extensionIndex = filename.lastIndexOf(".");
    const stem = extensionIndex < 0 ? filename : filename.slice(0, extensionIndex);
    const extension = extensionIndex < 0 ? "" : filename.slice(extensionIndex + 1);
    const name = titleCase(stem.replace(/^[0-9]+[-_]*/, ""));
    return extension.toLowerCase() === "gif" ? name + " (Live)" : name;
}

function compare(a, b) {
    const aPrefix = a.name.match(/^[0-9]+/);
    const bPrefix = b.name.match(/^[0-9]+/);
    if (aPrefix && bPrefix) {
        const difference = Number(aPrefix[0]) - Number(bPrefix[0]);
        if (difference)
            return difference;
    } else if (aPrefix || bPrefix) {
        return aPrefix ? -1 : 1;
    }
    return a.relativePath.localeCompare(b.relativePath);
}
