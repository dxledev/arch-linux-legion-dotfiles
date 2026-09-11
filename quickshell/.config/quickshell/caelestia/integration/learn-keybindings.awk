function trim(str) {
    sub(/^[[:space:]]+/, "", str)
    sub(/[[:space:]]+$/, "", str)
    return str
}

function normalize_mods(str,    n, i, parts, out) {
    str = trim(str)
    if (str == "") {
        return ""
    }

    n = split(str, parts, /[[:space:]]+/)
    out = ""
    for (i = 1; i <= n; i++) {
        if (parts[i] == "") {
            continue
        }
        if (out != "") {
            out = out " + "
        }
        out = out parts[i]
    }
    return out
}

function replace_vars(str,    changed, name) {
    changed = str
    for (name in vars) {
        gsub("\\" name, vars[name], changed)
    }
    return changed
}

/^[[:space:]]*\$/ {
    split($0, pair, "=")
    if (length(pair) >= 2) {
        name = trim(pair[1])
        value = trim(substr($0, index($0, "=") + 1))
        vars[name] = value
    }
    next
}

/^[[:space:]]*bind[a-z]*d[a-z]*[[:space:]]*=/ {
    split($0, pair, "=")
    right = trim(pair[2])
    count = split(right, fields, ",")
    if (count < 3) {
        next
    }

    mods = replace_vars(trim(fields[1]))
    key = replace_vars(trim(fields[2]))
    desc = trim(fields[3])

    if (desc == "") {
        next
    }

    left = normalize_mods(mods)
    if (left != "" && key != "") {
        left = left " + " key
    } else if (key != "") {
        left = key
    }

    print left " | " desc
}
