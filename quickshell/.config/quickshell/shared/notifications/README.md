# Shared notification history

Caelestia, Island, Noctalia and Waybar (wardnc) share one notification history.
A notification received in one shell mode stays in the history after a shell
reset or a switch to another mode. Removing or clearing it in one mode removes
it from all of them.

The store is wardnc's JSON Lines file, oldest record first:
`~/.local/state/wardnc/notification-history.jsonl`. wardnc's
`paths.history_file` setting, `WARDNC_HISTORY_FILE` or
`SHELL_NOTIFICATION_HISTORY` override it. Each record has `time` (UTC ISO 8601),
`app`, `summary`, `body`, `icon` and `id`. `image` (a file path) and `urgency`
(0–2) are optional. Readers preserve unknown fields.

Use `shared/notifications/history` instead of editing the file directly:

```bash
history list [--limit N]   # JSON array, newest first, with key and epochMs
history append JSON        # add a record; prints its key
history remove KEY|JSON…   # remove by key, or by {time, summary, body} match
history clear
history import FILE        # merge a Caelestia notifs.json or Noctalia history
```

Records with the same plain-text summary and body within two seconds describe
one notification. `append` keeps the first and fills its missing icon, image or
app. That folds the `~/bin/notify-send` wrapper's record into the one the active
shell saves. `list` folds older duplicates the same way. The script locks the
file, appends new lines without rewriting, and keeps unchanged lines
byte-identical because wardnc identifies loaded records by their text.

Each shell loads the history at startup and saves notifications it receives:

- Island: `island/services/NotificationService.qml` (newest 100).
- Caelestia: `caelestia/services/Notifs.qml` (newest 500). Closing a
  notification removes its record; a sender closing it keeps the record.
- Noctalia: `noctalia/integration/patches/0033-shared-notification-history.patch`
  keeps its own history file for images and actions, but drops entries removed
  elsewhere and adds records from other shells at startup.
- Waybar: wardnc reads, watches and appends to the file, and its clear button
  truncates it. Dismissing a single wardnc notification does not remove its
  record.

Transient notifications are not saved. Clearing all notifications in a shell
clears the whole store, including records beyond that shell's load limit.
