function clean(value) {
    return String(value || "").replace(/\x1b\[[0-9;?]*[A-Za-z]/g, "").replace(/[\x00-\x08\x0b-\x1f\x7f]/g, "").trim();
}

function fields(output) {
    const result = {};
    for (const line of clean(output).split("\n")) {
        const match = line.match(/^\s*([A-Za-z][A-Za-z ]{0,27}):\s*(.+)$/);
        if (match)
            result[match[1].trim().toLowerCase()] = match[2].trim();
    }
    return result;
}

function link(output) {
    for (const line of clean(output).split("\n")) {
        const parts = line.split(":");
        if (parts.length < 4)
            continue;
        const state = parts.pop();
        const device = parts.pop();
        const type = parts.pop();
        if (state !== "activated" || !/^proton\d*$/i.test(device) || !/^(wireguard|vpn|tun)$/.test(type))
            continue;
        const name = parts.join(":").replace(/\\([:\\])/g, "$1");
        return { connected: true, server: name.replace(/^ProtonVPN[\s:]+/i, ""), device: device };
    }
    return { connected: false, server: "", device: "" };
}

function status(output) {
    const data = fields(output);
    const state = (data.status || "").toLowerCase();
    const server = (data.server || "").match(/^(\S+)\s+in\s+(.+)$/);
    return {
        valid: /^(connected|connecting|disconnected)$/.test(state),
        connected: state === "connected",
        connecting: state === "connecting",
        server: server ? server[1] : data.server || "",
        location: server ? server[2] : "",
        details: Object.keys(data).filter(key => key !== "status" && key !== "server").map(key => ({
            label: key.charAt(0).toUpperCase() + key.slice(1), value: data[key]
        }))
    };
}

function signedIn(output) {
    const account = (fields(output).account || "").replace(/^['"]|['"]$/g, "");
    return account.length > 0 && account.toLowerCase() !== "none";
}

function countries(output) {
    const result = [];
    const seen = {};
    for (const line of clean(output).split("\n")) {
        const match = line.match(/^\s*(.+?)\s{2,}([A-Z]{2})\s*$/);
        if (match && !seen[match[2]]) {
            seen[match[2]] = true;
            result.push({ name: match[1].trim(), code: match[2] });
        }
    }
    return result;
}

function config(output) {
    const result = {};
    for (const line of clean(output).split("\n")) {
        const match = line.match(/^\s*([a-z][a-z-]+)\s{2,}(.+?)\s*$/);
        if (match)
            result[match[1]] = match[2];
    }
    return result;
}

function error(exitCode, output) {
    if (exitCode === 124 || exitCode === 137)
        return "Proton VPN did not respond in time. Retry to check the current connection.";
    if (exitCode === 127)
        return "Install proton-vpn-cli to control Proton VPN.";
    const lines = clean(output).split("\n");
    const message = lines.find(line => /^(error|usage error|authentication required)/i.test(line.trim()));
    return (message || "Proton VPN could not complete the request. Check your account and connection, then retry.").slice(0, 320);
}
