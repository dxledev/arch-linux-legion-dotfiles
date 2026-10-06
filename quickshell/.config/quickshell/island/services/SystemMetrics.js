function cpuUsage(previous, current) {
    if (!previous) return 0;
    const elapsed = current.total - previous.total;
    return elapsed > 0 ? Math.max(0, Math.min(1, 1 - (current.idle - previous.idle) / elapsed)) : 0;
}

function gibibytes(kibibytes) {
    return (kibibytes / 1048576).toFixed(1) + " GiB";
}

function uptime(seconds) {
    const hours = Math.floor(seconds / 3600);
    return (hours >= 24 ? Math.floor(hours / 24) + "d " : "") + (hours % 24) + "h " + Math.floor(seconds % 3600 / 60) + "m";
}
