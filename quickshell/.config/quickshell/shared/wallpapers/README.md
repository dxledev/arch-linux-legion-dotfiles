# Shared wallpaper relink

Caelestia, Island and Noctalia share one Dynamic wallpaper folder. Each shell
remembers the wallpaper it uses as a path. When Island renames or deletes a
Dynamic wallpaper, `relink` repoints the other shells' references from the old
path to the new one, so their next restore does not find a dangling link.

```bash
relink [--dry-run] [--replaced] [--noctalia-bin PATH] --state-root DIR OLD NEW
```

`--replaced` is for deletes, where NEW is a different image: it moves only `link` and
`settings` references, because `applied`, `pending` and `palette` describe the
contents of OLD and must not be relabelled.

- `--state-root` is required. There is no default, so tests cannot touch real
  state. Island passes the parent of its own state directory.
- `OLD` and `NEW` must be absolute and different. Usage errors exit 2.
- Otherwise it always exits 0. Per-target problems become entries in
  `warnings`, because the file operation that triggered the relink already
  happened.
- stdout is one JSON object: `{"updated": [{"file", "kind"}...], "warnings": [...]}`.
  `--dry-run` writes nothing and lists what would change.

Targets under `STATE_ROOT`, matched by exact string equality with `OLD`:

| kind       | file                                              |
|------------|---------------------------------------------------|
| `link`     | symlinks directly in `caelestia/` and `noctalia/` whose target is `OLD` |
| `applied`  | `noctalia/applied-wallpaper`, lines equal to `OLD` |
| `pending`  | `toggle-shell-mode/noctalia-wallpaper-pending`, lines equal to `OLD` |
| `settings` | `noctalia/settings.toml`, double-quoted basic strings equal to `OLD` |
| `palette`  | `{caelestia,noctalia,island}/aether-palettes/*.json`, `wallpaperPath` values equal to `OLD` |

Links are replaced atomically and never followed. Other symlinks, including
dangling ones, are left alone. Text files are rewritten atomically with their
permission bits kept, and only when something changed. Palette rewrites are
skipped if the result no longer parses as JSON. Everything else in each file
stays byte-identical.

Run `bash shared/wallpapers/tests/relink` to check it.

## Running Noctalia

Noctalia keeps its settings in memory and rewrites `settings.toml` on its next change, so an edit it never
loaded would be written back over. It reloads the file from an inotify event on the file name, but ignores the
first event after each of its own saves, and `noctalia msg config-reload` does not re-read the file. With
`--noctalia-bin PATH` (never defaulted; Island passes it) `relink`:

1. validates the edited text with `noctalia config validate` and refuses to write a file Noctalia would reject;
2. after writing, asks the running instance (`msg wallpaper-get`, default and per-monitor paths) what it holds
   and, if it still has the old wallpaper, rewrites the file once more to raise a fresh event (up to three
   times, about two seconds in all); it never uses `wallpaper-set`, which applies to every output;
3. warns, and still exits 0, if Noctalia never catches up. Nothing is probed when Noctalia is not running.

With `--replaced`, `settings.toml` changes only the `wallpaper.default`, `wallpaper.last` and
`wallpaper.monitors.*` sections, and `[[wallpaper.favorite]]` entries of the deleted file are removed, as
Noctalia's own delete does. This was checked against Noctalia's source and its validator, not a live instance.
