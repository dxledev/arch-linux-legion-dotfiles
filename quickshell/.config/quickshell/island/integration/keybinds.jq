def shortcut:
    . as $binding |
    [[64, "SUPER"], [4, "CTRL"], [8, "ALT"], [1, "SHIFT"],
     [2, "CAPS"], [16, "MOD2"], [32, "MOD3"], [128, "MOD5"]] |
    map(select((($binding.modmask // 0) / .[0] | floor) % 2 == 1) | .[1]) +
    [if ($binding.keycode // 0) > 0 then "CODE:" + ($binding.keycode | tostring)
     else $binding.key | ascii_upcase end] | join(" + ");

map(select((.description? | type) == "string" and (.description | test("\\S"))) |
    . as $binding | shortcut as $shortcut |
    {
        id: ([$binding.modmask, $binding.key, ($binding.keycode // 0), ($binding.submap // ""),
              ($binding.release // false), ($binding.longPress // false), ($binding.mouse // false),
              $binding.description, $binding.dispatcher] | tojson | @base64),
        description: $binding.description,
        shortcut: (($shortcut | sub("^SUPER \\+ CTRL \\+ ALT \\+ SHIFT \\+ "; "HYPER + ")) + (if $binding.release then " (release)" else "" end)
            + (if ($binding.submap // "") != "" then " [" + $binding.submap + "]" else "" end)),
        source: (if any($island[]; .shortcut == $shortcut and .description == $binding.description
            and .release == ($binding.release // false) and .submap == ($binding.submap // ""))
            then "Island" else "Global" end),
        dispatcher: $binding.dispatcher,
        args: ($binding.arg // "")
    }) | sort_by(.source, (.description | ascii_downcase), .shortcut)
