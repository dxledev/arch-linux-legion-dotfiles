# Shared clipboard history and pins

Caelestia, Island and Noctalia show one clipboard: the same history and the
same pinned entries. Copying in one shell mode, or pinning, unpinning and
deleting there, shows up in the others the next time they load or refresh.

Two stores hold it. No shell keeps a copy of its own.

**History** is cliphist's database (`~/.cache/cliphist/db`). The
`wl-paste --type text|image --watch cliphist store` watchers started by
`~/bin/launch-cliphist` from Hyprland's autostart fill it in every shell mode,
so history keeps growing while a shell is stopped or being switched. Shells
read it with `cliphist list`, decode a payload with `cliphist decode ID` and
remove entries with `cliphist delete`/`cliphist wipe`.

**Pins** are the favorites store written by Caelestia's native `Shell.Clipboard`
module, which Island also uses:

```
~/.local/share/caelestia/clipboard/        0700
    favorites.json                         0600  {"version":1,"items":[HASH, ...]}
    HASH.payload                           0600  the raw bytes of the pinned item
```

`HASH` is the lowercase SHA-256 of the payload bytes, exactly as `cliphist
decode` prints them, with nothing trimmed. `items` is the pin order. A pin is
the same item as a history row when their hashes match, and such a row is shown
once, as the pin. Writers add the payload before the manifest and delete the
payload after removing it from the manifest, so a manifest never names a missing
file. Caelestia treats a repeated or malformed hash, or a missing payload, as a
damaged store and stops using it, so keep to that format.

## Shells

- Island: `island/modules/clipboard/ClipboardService.qml`, a thin wrapper over
  `Shell.Clipboard` (`caelestia/integration/clipboard/`).
- Caelestia: `caelestia/modules/clipboard/ClipboardState.qml`, the same module.
- Noctalia: `noctalia/integration/patches/0036-shared-clipboard.patch`. Its
  `ClipboardService` keeps the Wayland data-control transport (live paste,
  keeping a selection after its app exits) but no longer records or encrypts its
  own history. `src/wayland/shared_clipboard_store.*` talks to cliphist and the
  favorites folder. Pins come first in manifest order, then up to
  `clipboard_history_max_entries` history rows, newest first. The list is
  reloaded at startup, whenever the panel opens, and shortly after Noctalia sees
  a new selection.

Noctalia used to keep an encrypted history under
`~/.local/state/noctalia/clipboard`. That is no longer read or written and was
not migrated; delete the folder if you want the space back.

## Behaviour to keep consistent

- Pinning appends to the end of `items`. Unpinning removes the hash and the
  payload. The history row, if cliphist still has it, becomes an ordinary
  entry again.
- Deleting a pin also deletes the history rows with the same hash, otherwise it
  would reappear as an unpinned entry.
- Clearing history wipes cliphist and keeps pins. Clearing pins empties
  `favorites.json` and removes every `*.payload`.
- Images are PNG, JPEG, GIF or BMP as `cliphist list` reports them. Pins of any
  other binary content are ignored by Noctalia.
- cliphist records no copy time, so Noctalia shows an entry's size alone.
- Noctalia lists at most `clipboard_history_max_entries` unpinned rows (default
  100, up to 10000, set in its clipboard settings), while Island and Caelestia
  list everything cliphist holds (750 by default).
- Noctalia no longer skips password-manager copies; cliphist's watchers store
  whatever is copied, in every shell mode.

## Overrides (Noctalia)

| Variable | Meaning |
|---|---|
| `NOCTALIA_CLIPHIST_BIN` | cliphist executable (default `cliphist` from `PATH`) |
| `NOCTALIA_CLIPHIST_DB` | cliphist database passed as `-db-path` |
| `NOCTALIA_CLIPBOARD_FAVORITES_DIR` | pin folder (default `$XDG_DATA_HOME/caelestia/clipboard`) |

Island reads the same folder through `favoritesDirectory` and the same
database through `historyDatabasePath`; neither is set by default.

Run `bash island/integration/tests/clipboard` for Island's checks. Noctalia's
`clipboard_service_test` covers history, pins and deduplication against a fake
cliphist.
