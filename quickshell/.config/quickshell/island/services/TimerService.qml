pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "TimerLogic.js" as TimerLogic

// Countdown timers. Each one is an absolute end time kept in a small file, so a shell restart, a reload or a
// suspend never loses or stretches a timer: whatever ended meanwhile fires when the shell is next up. The
// alert goes through notify-send into Island's own notification server, like any other app's.
Singleton {
    id: root

    readonly property string stateFile: Quickshell.env("ISLAND_TIMER_STATE") || ThemeService.stateDirectory + "/timers.json"
    readonly property string soundDirectory: Quickshell.env("ISLAND_TIMER_SOUND_DIR") || "/usr/share/sounds/freedesktop/stereo"
    readonly property string soundPlayer: Quickshell.env("ISLAND_TIMER_PLAYER") || "/usr/bin/pw-play"
    readonly property string notifySend: Quickshell.env("ISLAND_TIMER_NOTIFY_SEND") || "/usr/bin/notify-send"

    // Running timers, the one ending first at index 0. Replaced, never edited, when one is added or ends.
    property var timers: []
    // The clock the countdowns read; only ticks while a timer runs.
    property real now: Date.now()
    // Whether the next timer's alert stays until closed. Remembered, so a habit is set once.
    property bool keepAlert: false
    // Whether the next timer plays a sound when it ends, and which. Remembered like keepAlert.
    property bool soundEnabled: false
    property string soundName: TimerLogic.defaultSound
    readonly property var sounds: TimerLogic.sounds
    // Whether the next timer's alert offers Snooze, and for how many seconds. Remembered like the rest.
    property bool snoozeEnabled: false
    property int snoozeSeconds: TimerLogic.defaultSnooze
    property bool loaded: false
    property int serial: 0

    readonly property bool active: timers.length > 0
    readonly property var leading: active ? timers[0] : null
    readonly property real leadingRemaining: leading ? TimerLogic.remainingMs(leading, now) : 0
    readonly property real leadingProgress: leading ? TimerLogic.progress(leading, now) : 0
    readonly property bool leadingUrgent: leading ? TimerLogic.isUrgent(leading, now) : false
    readonly property bool leadingPaused: leading ? leading.paused : false
    // Whether any timer is counting down (the leading one is, if any is).
    readonly property bool running: active && !leadingPaused
    readonly property string leadingText: leading ? TimerLogic.formatRemaining(leadingRemaining) : ""
    // Timers beyond the one the island shows.
    readonly property int others: Math.max(0, timers.length - 1)

    // stayUntilClosed, sound (a key from sounds, "" for none) and snooze (seconds, 0 for none) default to the
    // remembered choices.
    function start(seconds, label, stayUntilClosed, sound, snooze) {
        const length = TimerLogic.clampSeconds(seconds);
        if (length <= 0 || timers.length >= TimerLogic.maximumTimers) return false;
        const started = Date.now();
        const timer = TimerLogic.createTimer(TimerLogic.makeId(started, ++serial), label, length,
            stayUntilClosed === undefined ? keepAlert : stayUntilClosed, started,
            sound === undefined ? (soundEnabled ? soundName : "") : sound,
            snooze === undefined ? (snoozeEnabled ? snoozeSeconds : 0) : snooze);
        now = started;
        timers = TimerLogic.sortTimers([...timers, timer]);
        save();
        return true;
    }

    function cancel(id) {
        if (!timers.some(timer => timer.id === id)) return;
        timers = timers.filter(timer => timer.id !== id);
        save();
    }

    // Pauses a timer, or resumes it when it is paused.
    function togglePause(id) {
        const timer = timers.find(item => item.id === id);
        if (!timer) return;
        const stamp = Date.now();
        now = stamp;
        timers = TimerLogic.sortTimers(timers.map(item => item !== timer ? item
            : timer.paused ? TimerLogic.resumeTimer(timer, stamp) : TimerLogic.pauseTimer(timer, stamp)));
        save();
    }

    // The Control Center's button: pauses every timer that is counting down, or, when none is, resumes them all.
    function toggleAllPaused() {
        if (!active) return;
        const stamp = Date.now();
        const pause = running;
        now = stamp;
        timers = TimerLogic.sortTimers(timers.map(item => pause ? TimerLogic.pauseTimer(item, stamp) : TimerLogic.resumeTimer(item, stamp)));
        save();
    }

    // Whole seconds left on a timer, as of now.
    function remainingSeconds(timer) {
        return Math.ceil(TimerLogic.remainingMs(timer, Date.now()) / 1000);
    }

    function cancelAll() {
        if (timers.length === 0) return;
        timers = [];
        save();
    }

    function setKeepAlert(value) {
        if (keepAlert === value) return;
        keepAlert = value;
        save();
    }

    function setSoundEnabled(value) {
        if (soundEnabled === value) return;
        soundEnabled = value;
        if (!value) stopSound();
        save();
    }

    function setSoundName(key) {
        if (!TimerLogic.knownSound(key) || soundName === key) return;
        soundName = key;
        save();
    }

    function setSnoozeEnabled(value) {
        if (snoozeEnabled === value) return;
        snoozeEnabled = value;
        save();
    }

    function setSnoozeSeconds(seconds) {
        const value = TimerLogic.clampSnooze(seconds);
        if (snoozeSeconds === value) return;
        snoozeSeconds = value;
        save();
    }

    // The sound being played, if any. Only one at a time: playing another, or stopSound(), cuts it off.
    property Process current: null
    // The sound being previewed from the panel, "" when none. Closing the panel cuts off a preview only.
    property string previewKey: ""
    readonly property bool previewing: previewKey !== ""
    // The timer whose alert is ringing, and its sound. An alert sound repeats until it is stopped, snoozed or
    // closed, so a timer that went off while you were away is not missed; no longer than ringLimit. An alert that
    // merely expires stops the repeating but lets the sound finish.
    property string ringId: ""
    property string ringKey: ""
    readonly property int ringLimit: Number(Quickshell.env("ISLAND_TIMER_RING_LIMIT") || 60000)
    // Alerts still open, by timer id, so their Snooze button knows what to put back.
    property var openAlerts: ({})

    // Plays one of the sounds once, after cutting off the one still playing. pw-play is used when it is there and
    // paplay otherwise; the shell hands itself over to the player (exec), so stopping reaches the player itself.
    function play(key) {
        if (!TimerLogic.knownSound(key)) return;
        stopSound();
        launch(key);
    }

    function launch(key) {
        current = playerComponent.createObject(root, {
            command: ["/usr/bin/sh", "-c", 'if [ -x "$1" ]; then exec "$1" "$2"; else exec /usr/bin/paplay "$2"; fi', "sh",
                soundPlayer, TimerLogic.soundFile(soundDirectory, key)],
            running: true
        });
    }

    // The panel's way of letting you hear a sound: the same as play(), but cut off when the panel closes.
    function preview(key) {
        play(key);
        previewKey = current !== null ? key : "";
    }

    function stopPreview() {
        if (previewing) stopSound();
    }

    // Rings an alert: the sound plays again and again until stopRinging(), the alert closing or the limit.
    function ring(timer) {
        if (!TimerLogic.knownSound(timer.sound)) return;
        stopSound();
        ringId = timer.id;
        ringKey = timer.sound;
        ringStop.interval = ringLimit;
        ringStop.restart();
        launch(timer.sound);
    }

    // Silences one alert's sound, and only that: another alert's sound keeps playing.
    function stopRinging(id) {
        if (ringId === id) stopSound();
    }

    function stopSound() {
        previewKey = "";
        ringId = "";
        ringStop.stop();
        again.stop();
        if (!current) return;
        const stopping = current;
        current = null;
        stopping.running = false;
    }

    Component {
        id: playerComponent
        Process {
            id: player
            onExited: (code, status) => {
                if (root.current === player) {
                    root.current = null;
                    root.previewKey = "";
                    // A player that fails (no sound file, no audio) must not be restarted in a loop.
                    if (root.ringId !== "" && code === 0) again.restart();
                }
                player.destroy();
            }
        }
    }

    Timer {
        id: again
        interval: 500
        onTriggered: if (root.ringId !== "" && !root.current) root.launch(root.ringKey)
    }

    Timer {
        id: ringStop
        onTriggered: root.stopSound()
    }

    Component {
        id: alertComponent
        // notify-send stays until the alert closes when it carries buttons; Island answers the buttons itself.
        Process { onExited: destroy() }
    }

    // Timers that have reached their end go off; a late one (shell closed, machine asleep) also says when it ended.
    function tick() {
        now = Date.now();
        const split = TimerLogic.partition(timers, now);
        if (split.due.length === 0) return;
        timers = split.running;
        for (const timer of split.due) alert(timer, now - timer.endsAt);
        save();
    }

    function alert(timer, lateBy) {
        const endedAt = new Date(timer.endsAt).toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
        const text = TimerLogic.alertText(timer, lateBy, endedAt);
        const args = [notifySend, "--app-name", NotificationService.timerApp];
        // No timeout is requested for an ordinary alert, so the popup lasts as long as Settings -> Notifications
        // says. One that stays until closed asks for none at all, which Island never times out.
        if (timer.indefinite) args.push("--urgency=critical", "--expire-time=0");
        // The hint ties the popup's buttons back to this timer; notify-send waits for the alert to close.
        const actions = TimerLogic.alertActions(timer);
        if (actions.length > 0) {
            args.push("--hint=string:" + NotificationService.timerHint + ":" + timer.id);
            for (const action of actions) args.push("--action=" + action.key + "=" + action.text);
            openAlerts[timer.id] = timer;
            alertComponent.createObject(root, {command: [...args, text.summary, text.body], running: true});
        } else {
            Quickshell.execDetached([...args, text.summary, text.body]);
        }
        if (timer.sound) ring(timer);
    }

    // A button on an alert was pressed. True when the alert should close with it.
    function alertAction(id, key) {
        const timer = openAlerts[id];
        if (key === "stop") {
            stopRinging(id);
            return false;
        }
        if (key !== "snooze" || !timer || !(timer.snooze > 0)) return false;
        if (timers.length >= TimerLogic.maximumTimers) return false;
        stopRinging(id);
        const started = Date.now();
        now = started;
        timers = TimerLogic.sortTimers([...timers, TimerLogic.snoozeTimer(timer, TimerLogic.makeId(started, ++serial), started)]);
        delete openAlerts[id];
        save();
        return true;
    }

    // The alert closed: by a button, a click or the notification list (the sound stops with it), or on its own when
    // its time ran out (expired: the sound being played finishes, but does not start again).
    function alertClosed(id, expired) {
        if (expired && ringId === id) {
            ringId = "";
            ringStop.stop();
            again.stop();
        } else stopRinging(id);
        delete openAlerts[id];
    }

    function save() {
        if (loaded) file.setText(TimerLogic.serialize(timers, {
            keepAlert: keepAlert, soundEnabled: soundEnabled, soundName: soundName,
            snoozeEnabled: snoozeEnabled, snoozeSeconds: snoozeSeconds
        }));
    }

    // Timers started before the file was read stay; the file's own are added to them.
    function restore(text) {
        const stored = TimerLogic.parseStored(text);
        const known = new Set(timers.map(timer => timer.id));
        keepAlert = stored.keepAlert;
        soundEnabled = stored.soundEnabled;
        soundName = stored.soundName;
        snoozeEnabled = stored.snoozeEnabled;
        snoozeSeconds = stored.snoozeSeconds;
        timers = TimerLogic.sortTimers([...timers, ...stored.timers.filter(timer => !known.has(timer.id))]);
        loaded = true;
        tick();
        save();
    }

    FileView {
        id: file
        path: root.stateFile
        atomicWrites: true
        printErrors: false
        onLoaded: root.restore(text())
        onLoadFailed: root.loaded = true
    }

    Timer {
        interval: 250
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.tick()
    }
}
