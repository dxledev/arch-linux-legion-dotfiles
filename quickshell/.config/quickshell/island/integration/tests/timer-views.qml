import QtQuick
import QtTest
import Quickshell
import "../../island"
import "../../core"
import "../../components"
import "../../services"
import "../../styles"
import "../../views"
import "../../windows"

ShellRoot {
    id: root
    property int phase: 0
    property int elapsed: 0
    property var note: ({})
    readonly property string stateFile: Quickshell.env("ISLAND_TIMER_STATE")
    readonly property string shots: Quickshell.env("TIMER_SHOTS")
    readonly property string playedFile: Quickshell.env("TIMER_PLAYED")
    property int shotsTaken: 0

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }

    function named(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const found = named(child, name);
            if (found) return found;
        }
        return null;
    }

    function next() { phase++; elapsed = 0; }

    function fileText(path) {
        const request = new XMLHttpRequest();
        request.open("GET", "file://" + path, false);
        try { request.send(); } catch (error) { return ""; }
        return request.responseText || "";
    }

    // How many times the fake player was asked for this sound.
    function played(key) {
        return fileText(playedFile).split("\n").filter(line => line.endsWith("/" + key + ".oga")).length;
    }

    // How many times a sound was cut off while playing.
    function stopped(key) {
        return fileText(playedFile + ".stopped").split("\n").filter(line => line.endsWith("/" + key + ".oga")).length;
    }

    function readoutShows() {
        const readout = named(compact, "timer-readout");
        return readout && readout.visible && /^0\d:\d\d$/.test(named(readout, "timer-label").text);
    }

    function entryFor(summary) {
        return NotificationService.entries.find(entry => entry.summary === summary) ?? null;
    }

    function shoot(item, name) {
        if (shots === "") return;
        shotsTaken++;
        item.grabToImage(result => { result.saveToFile(shots + "/" + name + ".png"); shotsTaken--; });
    }

    // Pointer position on the dial: minutes round the face, on the ring.
    function dialPoint(minutes, radius) {
        const angle = minutes / 60 * 2 * Math.PI;
        return Qt.point(dial.width / 2 + radius * Math.sin(angle), dial.height / 2 - radius * Math.cos(angle));
    }

    function tick() {
        elapsed += 40;
        if (shotsTaken > 0) { elapsed -= 40; return; }
        if (elapsed > 9000) throw new Error("Timed out in phase " + phase);
        const clock = named(compact, "clock-label"), readout = named(compact, "timer-readout");
        const panel = panelLoader.item;
        switch (phase) {
        case 0: {
            if (!ThemeService.ready || !TimerService.loaded || elapsed < 400) return;
            check(!TimerService.active && !readout.visible, "No timer, no readout");
            check(named(compact, "clock-label").parent.opacity === 1, "The clock shows while idle");
            note.idleWidth = compact.implicitWidth;
            check(TimerService.start(3, "Tea", false), "A timer starts");
            check(!TimerService.start(0, "x", false) && !TimerService.start(-4, "x", false), "An empty timer is refused");
            next();
            break;
        }
        case 1: {
            if (elapsed < 500) return;
            check(TimerService.active && readout.visible && readout.opacity === 1, "The readout shows while a timer runs");
            check(named(compact, "clock-label").parent.opacity === 0, "The timer takes the clock's place");
            check(/^00:0[123]$/.test(named(readout, "timer-label").text), "The readout counts down: " + named(readout, "timer-label").text);
            const ring = named(readout, "timer-ring");
            check(ring.visible && ring.progress > 0 && ring.progress <= 1, "The ring shows what is left: " + ring.progress);
            check(compact.implicitWidth === note.idleWidth, "The island does not change width for a timer: " + compact.implicitWidth);
            check(Math.abs(readout.x + readout.width / 2 - compact.width / 2) < 1.5, "The readout sits where the clock was");
            check(named(readout, "timer-label").color.toString() === Theme.warning.toString(), "The last seconds turn warning-coloured");
            check(!named(readout, "timer-others").visible, "A lone timer has no +N");
            check(fileText(stateFile).includes('"label":"Tea"'), "The timer is saved to disk: " + fileText(stateFile));
            shoot(compactFrame, "island-timer");
            next();
            break;
        }
        case 2: {
            if (TimerService.active || !entryFor("Tea")) return;
            const entry = entryFor("Tea");
            check(entry.body === "Your 3 s timer is up." && entry.app === NotificationService.timerApp, "The alert names the timer: " + entry.body);
            check(entry.totalDuration > 0, "An ordinary alert expires on its own: " + entry.totalDuration);
            check(TimerService.timers.length === 0 && fileText(stateFile).includes('"timers":[]'), "A finished timer leaves the file");
            entry.dismiss();
            next();
            break;
        }
        case 3: {
            if (elapsed < 500) return;
            check(named(compact, "clock-label").parent.opacity === 1 && !readout.visible, "The clock returns when the timer ends");
            check(TimerService.start(1, "Laundry", true), "Start a timer whose alert stays");
            next();
            break;
        }
        case 4: {
            const entry = entryFor("Laundry");
            if (!entry) return;
            check(entry.totalDuration === 0 && entry.remaining === 0 && entry.countdownProgress === 0, "A staying alert has no timeout or countdown ring");
            note.stayed = elapsed;
            next();
            break;
        }
        case 5: {
            if (elapsed < 1500) return;
            const entry = entryFor("Laundry");
            check(entry && !entry.closed && entry.popup, "The staying alert is still up");
            entry.dismiss();
            NotificationService.doNotDisturb = true;
            check(TimerService.start(1, "", false), "Start a timer under Do Not Disturb");
            next();
            break;
        }
        case 6: {
            const entry = entryFor("Timer finished");
            if (!entry) return;
            check(entry.popup && !entry.closed, "A timer gets through Do Not Disturb");
            Quickshell.execDetached([Quickshell.env("TIMER_REAL_NOTIFY_SEND") || "/usr/bin/notify-send", "--app-name", "Other", "Quiet", "held back"]);
            next();
            break;
        }
        case 7: {
            if (elapsed < 900) return;
            check(!entryFor("Quiet") && NotificationService.history.count >= 3, "Other apps are still held back and kept in history");
            NotificationService.doNotDisturb = false;
            entryFor("Timer finished").dismiss();
            check(TimerService.start(600, "Slow", false) && TimerService.start(60, "Quick", false), "Two timers at once");
            next();
            break;
        }
        case 8: {
            if (elapsed < 500) return;
            check(TimerService.leading.label === "Quick" && TimerService.others === 1, "The one ending first leads");
            check(named(readout, "timer-others").visible && named(readout, "timer-others").text === "+1", "The island counts the others");
            check(/^(01:00|00:5\d)$/.test(named(readout, "timer-label").text), "It shows the leading timer: " + named(readout, "timer-label").text);
            TimerService.cancel(TimerService.leading.id);
            check(TimerService.leading.label === "Slow" && TimerService.others === 0, "Cancelling hands the island to the next");
            TimerService.cancelAll();
            check(!TimerService.active, "Cancel all stops everything");
            TimerService.setKeepAlert(true);
            check(TimerService.start(3600, "Persist", undefined), "A timer takes the remembered alert choice");
            next();
            break;
        }
        case 9: {
            if (elapsed < 400) return;
            const text = fileText(stateFile);
            check(text.includes('"keepAlert":true') && text.includes('"label":"Persist"') && text.includes('"indefinite":true'), "Timer and choice are on disk: " + text);
            // A restart: timers vanish from memory, the file brings them back, and one that ended while away goes off.
            TimerService.timers = [];
            const stale = JSON.stringify({version: 1, keepAlert: false, timers: [
                {id: "old", label: "Old", durationMs: 60000, startedAt: Date.now() - 3600000, endsAt: Date.now() - 3000000, indefinite: false}
            ]});
            TimerService.restore(text);
            check(TimerService.timers.length === 1 && TimerService.leading.label === "Persist" && TimerService.keepAlert, "Timers survive a restart");
            TimerService.restore(stale);
            check(TimerService.timers.length === 1 && TimerService.leading.label === "Persist", "A late timer is not kept");
            next();
            break;
        }
        case 10: {
            const entry = entryFor("Old");
            if (!entry) return;
            check(entry.body.startsWith("Your 1 min timer is up. It ended at "), "A late alert says when the timer ended: " + entry.body);
            entry.dismiss();
            TimerService.cancelAll();
            TimerService.setKeepAlert(false);
            panelLoader.active = true;
            next();
            break;
        }
        case 11: {
            if (!panel || elapsed < 500) return;
            check(panel.activeFocus, "The panel takes the keyboard");
            check(!named(panel, "timer-running").visible, "No list while nothing runs");
            check(!named(panel, "timer-start-button").enabled, "Start waits for a time");
            check(named(panel, "timer-dial-hint").visible, "The empty dial says what to do");
            for (const digit of "1500") check(panel.pressKey(Qt.Key_0 + Number(digit), digit), "Digits are used");
            next();
            break;
        }
        case 12: {
            check(panel.digits === "1500" && panel.seconds === 900, "Typing 1 5 0 0 dials 15:00: " + panel.digits);
            check(named(panel, "timer-dial-time").text === "15:00", "The dial reads what was typed");
            check(panel.pressKey(Qt.Key_Backspace, ""), "Backspace is used");
            check(panel.digits === "150" && panel.seconds === 110, "Backspace drops a digit");
            const preset = named(panel, "timer-preset-5");
            check(input.mouseClick(preset, preset.width / 2, preset.height / 2, Qt.LeftButton, Qt.NoModifier, 0) && panel.seconds === 410, "+5 min adds to the dial");
            const clear = named(panel, "timer-preset-clear");
            check(input.mouseClick(clear, clear.width / 2, clear.height / 2, Qt.LeftButton, Qt.NoModifier, 0) && panel.seconds === 0, "Clear empties the dial");
            check(!clear.enabled, "Clear rests when there is nothing to clear");
            // The dial: pressing the ring sets that minute, a drag across 12 o'clock carries on to the full hour.
            const quarter = dialPoint(15, 80);
            input.mouseClick(dial, quarter.x, quarter.y, Qt.LeftButton, Qt.NoModifier, 0);
            check(panel.seconds === 900, "Clicking 3 o'clock dials 15 minutes: " + panel.seconds);
            const middle = dialPoint(0, 4);
            input.mouseClick(dial, middle.x, middle.y, Qt.LeftButton, Qt.NoModifier, 0);
            check(panel.seconds === 900, "The middle of the face does not turn the dial");
            const from = dialPoint(55, 80), to = dialPoint(2, 80);
            input.mousePress(dial, from.x, from.y, Qt.LeftButton, Qt.NoModifier, 0);
            check(panel.seconds === 55 * 60, "Pressing 55 minutes dials 55: " + panel.seconds);
            input.mouseMove(dial, to.x, to.y, 0, Qt.LeftButton, Qt.NoModifier);
            check(panel.seconds === 3600, "Dragging past 12 o'clock reaches the full hour: " + panel.seconds);
            input.mouseRelease(dial, to.x, to.y, Qt.LeftButton, Qt.NoModifier, 0);
            const back = dialPoint(30, 80);
            input.mouseClick(dial, back.x, back.y, Qt.LeftButton, Qt.NoModifier, 0);
            check(panel.seconds === 1800, "Clicking 6 o'clock dials 30 minutes");
            next();
            break;
        }
        case 13: {
            // Label, staying alert, start.
            const field = named(panel, "timer-label-field"), toggle = named(panel, "timer-keep-alert"), start = named(panel, "timer-start-button");
            if (!note.dialed) {
                panel.digits = "";
                for (const digit of "200") panel.pressKey(Qt.Key_0 + Number(digit), digit);
                field.text = "Pasta";
                check(!toggle.checked, "Alerts expire unless asked otherwise");
                check(input.mouseClick(toggle, toggle.width - 20, toggle.height / 2, Qt.LeftButton, Qt.NoModifier, 0) && TimerService.keepAlert && toggle.checked, "The toggle keeps the alert");
                check(start.enabled && panel.startLabel === "Start 2 min timer", "Start names what it will do: " + panel.startLabel);
                note.dialed = elapsed;
                return;
            }
            // The dial eases to its new wedge; the picture waits for it.
            if (!note.dialShot) {
                if (elapsed - note.dialed < 500) return;
                note.dialShot = true;
                shoot(panelFrame, "panel-dialed");
                return;
            }
            check(input.mouseClick(start, start.width / 2, start.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Click start");
            check(TimerService.timers.length === 1, "A timer is running");
            const timer = TimerService.leading;
            check(timer.label === "Pasta" && timer.indefinite && Math.abs(timer.durationMs - 120000) < 1, "It carries the label, the choice and the time");
            check(panel.digits === "" && field.text === "", "The form clears for the next timer");
            // Enter starts too, and a second timer joins the first.
            panel.pressKey(Qt.Key_9, "9");
            panel.pressKey(Qt.Key_0, "0");
            check(panel.pressKey(Qt.Key_Return, "\r"), "Enter is used");
            check(!panel.pressKey(Qt.Key_A, "a"), "Other keys are left alone");
            check(TimerService.timers.length === 2 && TimerService.leading.durationMs === 90000, "Enter starts the timer, and the shorter one leads: " + JSON.stringify(TimerService.timers.map(t => t.durationMs)));
            next();
            break;
        }
        case 14: {
            if (elapsed < 600) return;
            const running = named(panel, "timer-running");
            check(running.visible && named(panel, "timer-list").count === 2, "Both timers are listed");
            const rows = TimerService.timers.map(timer => named(panel, "timer-row-" + timer.id));
            check(rows.every(row => row), "Each timer has a row");
            check(named(rows[0], "timer-row-label").text === "Timer" && named(rows[1], "timer-row-label").text === "Pasta", "A timer without a label is just Timer");
            check(/^01:(2|3)\d$|^01:30$/.test(named(rows[0], "timer-row-remaining").text), "The row counts down: " + named(rows[0], "timer-row-remaining").text);
            if (!note.listed) { note.listed = true; shoot(panelFrame, "panel-running"); return; }
            const cancel = named(rows[0], "timer-row-cancel");
            check(input.mouseClick(cancel, cancel.width / 2, cancel.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Cancel a timer");
            check(TimerService.timers.length === 1 && TimerService.leading.label === "Pasta", "Only that timer is gone");
            TimerService.cancelAll();
            next();
            break;
        }
        case 15: {
            // The expanded island: the timer sits where the clock did, and clicking it opens the panel.
            if (elapsed < 400) return;
            TimerService.start(300, "", false);
            next();
            break;
        }
        case 16: {
            if (elapsed < 600) return;
            const expandedReadout = named(expandedSection, "timer-readout");
            check(expandedReadout.visible && expandedReadout.interactive, "The expanded island shows the timer");
            check(named(expandedSection, "clock-label").parent.opacity === 0, "It replaces the clock there too");
            if (!note.expandedShot) { note.expandedShot = true; shoot(expandedFrame, "expanded-timer"); return; }
            IslandState.mode = IslandState.expandedMode;
            const open = named(expandedReadout, "timer-readout-open");
            check(input.mouseClick(open, open.width / 2, open.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Click the timer");
            check(IslandState.mode === IslandState.timerMode, "Clicking the timer opens the timer panel");
            IslandController.reset();
            next();
            break;
        }
        case 17: {
            // Lyrics on: the line stays and the timer shrinks to its ring, at the right of the line.
            if (elapsed < 900) return;
            const lyricReadout = named(lyricCompact, "timer-readout"), line = named(lyricCompact, "island-lyric-line");
            check(lyricReadout.visible && lyricReadout.opacity === 1 && line.opacity === 1, "Lyrics and the timer show together");
            const lyricLabel = named(lyricReadout, "timer-label");
            check(!lyricLabel.visible && lyricReadout.blend === 1, "With lyrics the time is gone and only the ring is left");
            check(lyricReadout.ring.visible && Math.abs(lyricReadout.width - lyricReadout.ringWidth) < 1.5, "The timer is as wide as its ring: " + lyricReadout.width);
            check(Math.abs(lyricReadout.x + lyricReadout.width - (lyricCompact.width - 16)) < 1.5, "The ring sits at the island's right edge: " + (lyricReadout.x + lyricReadout.width) + " of " + lyricCompact.width);
            check(lyricReadout.x >= lyricCompact.width / 2 + 30, "The ring leaves the middle of the island to the line");
            // What is painted, not just where the box is: the visible slot's text, centred in the room left of the ring.
            const slot = line.children.find(child => child.opacity === 1), painted = line.x + slot.x + slot.children[0].x + slot.children[0].width / 2;
            check(Math.abs(painted - (lyricCompact.width - lyricCompact.timerSlot) / 2) < 1.5, "The line is centred beside the ring: " + painted + " vs " + (lyricCompact.width - lyricCompact.timerSlot) / 2);
            const contentRight = line.x + (line.width + line.contentWidth) / 2;
            check(contentRight <= lyricReadout.x, "The line ends before the ring: " + contentRight + " vs " + lyricReadout.x);
            check(line.x + (line.width - line.contentWidth) / 2 >= 0, "The line stays inside the island");
            check(lyricCompact.implicitWidth >= 340, "Lyrics keep their minimum width: " + lyricCompact.implicitWidth);
            if (!note.lyricShot) { note.lyricShot = true; shoot(lyricFrame, "island-lyrics-timer"); return; }
            TimerService.cancelAll();
            next();
            break;
        }
        case 18: {
            // Sounds: a switch reveals the list; nothing plays until a play button is pressed.
            const sw = named(panel, "timer-sound-switch"), box = named(panel, "timer-sounds");
            if (!note.soundSetup) {
                check(!TimerService.soundEnabled && box.height === 0 && !box.visible, "The sound list waits until sound is on");
                check(TimerService.sounds.length >= 4 && named(panel, "setting-choice-"), "The panel offers the sounds in a dropdown");
                check(played("alarm-clock-elapsed") === 0, "Nothing has played yet");
                check(input.mouseClick(sw, sw.width - 20, sw.height / 2, Qt.LeftButton, Qt.NoModifier, 0) && TimerService.soundEnabled, "The switch turns sound on");
                note.soundSetup = elapsed;
                return;
            }
            if (elapsed - note.soundSetup < 600) return;
            check(box.visible && box.opacity === 1 && box.height >= 40, "The dropdown opens: " + box.height);
            check(played("alarm-clock-elapsed") === 0 && !TimerService.previewing, "Turning sound on plays nothing: " + fileText(playedFile));
            const combo = named(panel, "setting-choice-"), preview = named(panel, "setting-choice-preview-selected");
            check(combo.displayText === "Alarm clock" && combo.width === named(panel, "timer-options-column").width - 48, "The first sound is chosen to begin with, and the label fits: " + combo.displayText + " " + combo.width);
            check(preview.visible && preview.mapToItem(named(panel, "timer-options-column"), preview.width, 0).x <= named(panel, "timer-options-column").width, "The play button fits beside the dropdown");
            combo.popup.open();
            check(combo.popup.visible && combo.popup.contentItem.count === TimerService.sounds.length && IslandState.dropdownArea, "The dropdown lists every sound and joins the input mask");
            combo.popup.close();
            if (!note.soundShot) { note.soundShot = true; shoot(panelFrame, "panel-sounds"); return; }
            check(input.mouseClick(preview, 20, 20, Qt.LeftButton, Qt.NoModifier, 0), "The play button beside the dropdown is pressed");
            check(TimerService.previewKey === "alarm-clock-elapsed", "It previews the chosen sound: " + TimerService.previewKey);
            next();
            break;
        }
        case 19: {
            if (elapsed < 500) return;
            const preview = named(panel, "setting-choice-preview-selected");
            check(played("alarm-clock-elapsed") === 1 && stopped("alarm-clock-elapsed") === 0, "The sound plays once: " + fileText(playedFile));
            check(preview.playing, "The button shows that it is playing");
            check(input.mouseClick(preview, 20, 20, Qt.LeftButton, Qt.NoModifier, 0) && TimerService.previewKey === "" && !preview.playing, "Pressing it again stops the preview");
            next();
            break;
        }
        case 20: {
            if (elapsed < 400) return;
            check(stopped("alarm-clock-elapsed") === 1, "The stopped preview is cut off: " + fileText(playedFile + ".stopped"));
            named(panel, "setting-choice-").popup.open();
            next();
            break;
        }
        case 21: {
            // Every sound in the list has its own play button, which leaves the list open and the choice alone.
            if (elapsed < 300) return;
            const combo = named(panel, "setting-choice-"), bell = named(combo.popup.contentItem, "setting-choice-preview-bell");
            check(bell && bell.visible && named(combo.popup.contentItem, "setting-choice-preview-complete"), "Every sound has a play button");
            check(input.mouseClick(bell, 15, 15, Qt.LeftButton, Qt.NoModifier, 0), "A sound's play button is pressed");
            check(TimerService.previewKey === "bell" && combo.popup.visible, "It previews that sound and the list stays open: " + TimerService.previewKey);
            check(TimerService.soundName === "alarm-clock-elapsed", "Previewing does not choose the sound");
            next();
            break;
        }
        case 22: {
            if (elapsed < 500) return;
            const combo = named(panel, "setting-choice-"), bellIndex = TimerService.sounds.findIndex(sound => sound.key === "bell");
            check(played("bell") === 1 && named(combo.popup.contentItem, "setting-choice-preview-bell").playing, "The list's button shows that it is playing");
            combo.currentIndex = bellIndex;
            combo.activated(bellIndex);
            combo.popup.close();
            check(TimerService.soundName === "bell" && combo.displayText === "Bell", "The choice is shown: " + combo.displayText);
            check(!TimerService.previewing, "Choosing another sound ends the preview");
            next();
            break;
        }
        case 23: {
            if (elapsed < 700) return;
            check(played("bell") === 1, "Choosing a sound does not play it: " + fileText(playedFile));
            check(stopped("bell") === 1, "Choosing another sound cuts off the one playing: " + fileText(playedFile + ".stopped"));
            check(fileText(stateFile).includes('"soundEnabled":true') && fileText(stateFile).includes('"soundName":"bell"'), "The choice is saved: " + fileText(stateFile));
            panel.digits = "";
            panel.pressKey(Qt.Key_2, "2");
            check(panel.pressKey(Qt.Key_Return, "\r"), "Start a 2 second timer");
            check(TimerService.leading.sound === "bell", "The timer carries the chosen sound");
            check(TimerService.start(60, "", false, "complete") && TimerService.start(61, "", false, "") && TimerService.start(62, "", false, "../evil"), "Timers take an explicit sound");
            const sounds = TimerService.timers.map(timer => timer.sound);
            check(sounds.join() === "bell,complete,,", "A sound is kept only if known: " + sounds.join("|"));
            TimerService.cancel(TimerService.timers[1].id);
            TimerService.cancel(TimerService.timers[1].id);
            TimerService.cancel(TimerService.timers[1].id);
            next();
            break;
        }
        case 24: {
            if (TimerService.active) return;
            // The player takes a moment to start and note what it plays.
            if (!note.ended) note.ended = elapsed;
            if (elapsed - note.ended < 400) return;
            check(played("bell") === 2, "The sound plays when the timer ends: " + fileText(playedFile));
            check(stopped("bell") === 1 && TimerService.ringId !== "" && !TimerService.previewing, "The alert's sound is ringing, and is not a preview");
            // Turning sound off cuts off the alarm that is playing, then the alert is closed.
            const sw = named(panel, "timer-sound-switch");
            check(input.mouseClick(sw, sw.width - 20, sw.height / 2, Qt.LeftButton, Qt.NoModifier, 0) && !TimerService.soundEnabled, "The switch turns sound off");
            NotificationService.entries.slice().forEach(entry => entry.dismiss());
            check(TimerService.start(1, "Quiet", false) && TimerService.leading.sound === "", "With sound off a timer is silent");
            next();
            break;
        }
        case 25: {
            if (elapsed < 600 || TimerService.active || !entryFor("Quiet")) return;
            note.quietAt = elapsed;
            check(entryFor("Quiet"), "The silent timer still alerts");
            check(stopped("bell") === 2, "Turning sound off cuts off the sound playing: " + fileText(playedFile + ".stopped"));
            next();
            break;
        }
        case 26: {
            if (elapsed < 900) return;
            if (!note.snoozeStage) {
                check(played("bell") === 2, "A silent timer plays nothing: " + fileText(playedFile));
                check(named(panel, "timer-sounds").height === 0, "The list closes with the switch");
                NotificationService.entries.slice().forEach(entry => entry.dismiss());
                // Snoozing: a switch reveals the length, which is chosen from a dropdown without a play button.
                const sw = named(panel, "timer-snooze-switch");
                check(!TimerService.snoozeEnabled && named(panel, "timer-snooze").height === 0 && !named(panel, "timer-snooze").visible, "The snooze length waits until snoozing is allowed");
                check(input.mouseClick(sw, sw.width - 20, sw.height / 2, Qt.LeftButton, Qt.NoModifier, 0) && TimerService.snoozeEnabled, "The switch allows snoozing");
                note.snoozeStage = elapsed;
                return;
            }
            if (elapsed - note.snoozeStage < 600) return;
            const box = named(panel, "timer-snooze"), combo = named(box, "setting-choice-");
            check(box.visible && box.opacity === 1 && box.height >= 40, "The snooze length opens: " + box.height);
            if (!note.snoozeShot) {
                check(combo.displayText === "Snooze for 5 min" && combo.width === named(panel, "timer-options-column").width && !named(box, "setting-choice-preview-selected").visible, "It starts at 5 minutes, fills the row and has no play button: " + combo.displayText);
                note.snoozeShot = true;
                shoot(panelFrame, "panel-snooze");
                return;
            }
            const index = combo.model.indexOf("600");
            check(index > 0, "10 minutes is offered");
            if (!note.chosen) {
                combo.currentIndex = index;
                combo.activated(index);
                check(TimerService.snoozeSeconds === 600 && combo.displayText === "Snooze for 10 min", "The length is chosen: " + combo.displayText);
                note.chosen = elapsed;
                return;
            }
            if (elapsed - note.chosen < 400) return;
            check(fileText(stateFile).includes('"snoozeSeconds":600'), "The length is saved: " + fileText(stateFile));
            TimerService.setSnoozeSeconds(45);
            check(combo.model.indexOf("45") >= 0 && combo.displayText === "Snooze for 45 s", "A length set from outside is still shown: " + combo.displayText);
            TimerService.setSnoozeEnabled(false);
            next();
            break;
        }
        case 27: {
            // The lists stay inside the panel, which is now short: each opens upward if there is no room below.
            if (!note.both) {
                TimerService.setSoundEnabled(true);
                TimerService.setSnoozeEnabled(true);
                note.both = elapsed;
                note.listing = 0;
                return;
            }
            if (elapsed - note.both < 700) return;
            const boxes = ["timer-sounds", "timer-snooze"];
            const combo = named(named(panel, boxes[note.listing]), "setting-choice-");
            if (!note.listOpened) { combo.popup.open(); note.listOpened = elapsed; return; }
            if (elapsed - note.listOpened < 300) return;
            const corner = combo.mapToItem(panel, combo.popup.x, combo.popup.y);
            check(combo.popup.visible && corner.y >= 0 && corner.y + combo.popup.height <= panel.height,
                  boxes[note.listing] + " list stays inside the panel: " + corner.y + " to " + (corner.y + combo.popup.height) + " of " + panel.height);
            combo.popup.close();
            note.listOpened = 0;
            if (++note.listing < boxes.length) return;
            TimerService.setSoundEnabled(false);
            TimerService.setSnoozeEnabled(false);
            next();
            break;
        }
        case 28: {
            // A preview does not outlive the panel; an alert that is ringing does.
            if (elapsed < 200) return;
            TimerService.setSoundEnabled(true);
            TimerService.preview("complete");
            check(TimerService.previewing, "A preview is marked as one");
            next();
            break;
        }
        case 29: {
            if (elapsed < 500) return;
            if (!note.closed) {
                check(played("complete") === 1 && stopped("complete") === 0, "The preview is playing: played " + played("complete") + ", stopped " + stopped("complete"));
                note.closed = elapsed;
                panelLoader.active = false;
                return;
            }
            if (elapsed - note.closed < 500) return;
            check(stopped("complete") === 1 && !TimerService.previewing, "Closing the panel cuts off the preview: " + fileText(playedFile + ".stopped"));
            TimerService.play("complete");
            check(!TimerService.previewing, "A plain play is not a preview");
            TimerService.stopPreview();
            check(TimerService.current !== null, "Sound that is not a preview keeps playing when a panel closes");
            TimerService.stopSound();
            TimerService.setSoundEnabled(false);
            next();
            break;
        }
        case 30: {
            // The alert's buttons. Stop silences the alarm and leaves the alert up; Snooze closes it and the timer
            // comes back a few seconds later. A short sound shows the alarm repeating while the alert is up.
            TimerService.setSoundEnabled(true);
            TimerService.setSoundName("message-new-instant");
            TimerService.setSnoozeEnabled(true);
            TimerService.setSnoozeSeconds(2);
            check(TimerService.start(1, "Wake", true), "Start a timer that can be snoozed");
            check(TimerService.leading.snooze === 2 && TimerService.leading.sound === "message-new-instant", "The timer carries the snooze length and the sound");
            next();
            break;
        }
        case 31: {
            if (TimerService.active || !entryFor("Wake")) return;
            if (!note.ringing) note.ringing = elapsed;
            if (elapsed - note.ringing < 2900) return;
            const entry = entryFor("Wake");
            check(fileText(stateFile).includes('"snoozeEnabled":true') && fileText(stateFile).includes('"snoozeSeconds":2'), "The snooze choice is saved: " + fileText(stateFile));
            check(entry.actions.map(action => action.identifier).join() === "stop,snooze" && entry.actions.map(action => action.text).join() === "Stop,Snooze", "The alert has a Stop and a Snooze button: " + entry.actions.map(action => action.identifier));
            check(entry.timerId() !== "" && TimerService.ringId === entry.timerId(), "The alarm belongs to the alert");
            check(played("message-new-instant") >= 3, "The alarm repeats while its alert is up: " + played("message-new-instant"));
            note.rings = played("message-new-instant");
            entry.invoke(entry.actions.find(action => action.identifier === "stop"));
            check(!entry.closed && entryFor("Wake") === entry, "Stop leaves the alert up");
            check(TimerService.ringId === "" && TimerService.current === null, "Stop silences the alarm");
            next();
            break;
        }
        case 32: {
            if (elapsed < 2200) return;
            const entry = entryFor("Wake");
            check(played("message-new-instant") === note.rings, "The alarm does not come back after Stop: " + played("message-new-instant") + " vs " + note.rings);
            check(!entry.closed, "The alert is still up");
            entry.invoke(entry.actions.find(action => action.identifier === "snooze"));
            check(entry.closed, "Snooze closes the alert");
            check(TimerService.timers.length === 1 && TimerService.leading.snoozed && TimerService.leading.label === "Wake"
                && TimerService.leading.durationMs === 2000 && TimerService.leading.indefinite && TimerService.leading.sound === "message-new-instant",
                "Snooze puts the timer back with its label, sound and alert");
            next();
            break;
        }
        case 33: {
            if (!note.snoozeSeen) {
                if (elapsed < 300) return;
                check(readoutShows(), "The island shows the snoozed timer");
                note.snoozeSeen = true;
            }
            const again = NotificationService.entries.find(entry => entry.summary === "Wake" && !entry.closed);
            if (TimerService.active || !again) return;
            check(again.body === "Your 1 s timer is up again.", "The snoozed alert says what it is: " + again.body);
            check(again.actions.length === 2, "A snoozed alert can be snoozed again");
            check(played("message-new-instant") > note.rings && TimerService.ringId === again.timerId(), "The alarm sounds again when the snooze is up");
            again.dismiss();
            check(TimerService.ringId === "", "Closing the alert ends the alarm");
            next();
            break;
        }
        case 34: {
            // Buttons follow the choices made when the timer started, and Stop never touches another alert's sound.
            TimerService.setSnoozeEnabled(false);
            check(TimerService.start(1, "First", true) && TimerService.start(2, "Second", true), "Start two alarms");
            next();
            break;
        }
        case 35: {
            if (TimerService.active || !entryFor("Second")) return;
            const first = entryFor("First"), second = entryFor("Second");
            check(first.actions.map(action => action.identifier).join() === "stop", "Without snooze an alert only has Stop: " + first.actions.map(action => action.identifier));
            check(TimerService.ringId === second.timerId() && TimerService.current !== null, "The alarm that went off last is ringing");
            first.invoke(first.actions[0]);
            check(TimerService.ringId === second.timerId() && TimerService.current !== null, "Stop on one alert leaves another alert's alarm ringing");
            check(!first.closed, "Stop leaves that alert up too");
            second.invoke(second.actions[0]);
            check(TimerService.ringId === "" && TimerService.current === null, "Stop on the ringing alert silences it");
            NotificationService.entries.slice().forEach(entry => entry.dismiss());
            TimerService.setSoundEnabled(false);
            TimerService.setSnoozeEnabled(true);
            check(TimerService.start(1, "Mute", true), "Start a timer with no sound");
            next();
            break;
        }
        case 36: {
            if (TimerService.active || !entryFor("Mute")) return;
            const entry = entryFor("Mute");
            check(entry.actions.map(action => action.identifier).join() === "snooze", "Without a sound an alert has no Stop: " + entry.actions.map(action => action.identifier));
            entry.dismiss();
            TimerService.setSoundEnabled(true);
            TimerService.setSnoozeEnabled(false);
            check(TimerService.start(1, "Long", true), "Start an alarm to leave ringing");
            next();
            break;
        }
        case 37: {
            // An alarm nobody answers does not ring for ever.
            if (TimerService.active || !entryFor("Long")) return;
            if (!note.longRing) { note.longRing = elapsed; check(TimerService.ringId !== "", "The alarm is ringing"); }
            if (elapsed - note.longRing < 4400) return;
            check(TimerService.ringId === "" && TimerService.current === null, "The alarm stops by itself after the limit");
            check(!entryFor("Long").closed, "The alert is still up");
            NotificationService.entries.slice().forEach(entry => entry.dismiss());
            TimerService.setSoundEnabled(false);
            next();
            break;
        }
        case 38: {
            // An alert that runs out of time on its own lets the sound finish, but it does not start again.
            TimerService.setSoundEnabled(true);
            TimerService.setSoundName("complete");
            note.completeStopped = stopped("complete");
            note.completePlayed = played("complete");
            check(TimerService.start(1, "Expire", false), "Start an alarm whose alert will expire");
            next();
            break;
        }
        case 39: {
            if (TimerService.active) return;
            const entry = entryFor("Expire");
            if (!note.expireSeen) {
                if (!entry) return;
                check(TimerService.ringId !== "", "The alarm is ringing");
                note.expireSeen = true;
            }
            if (entry && !entry.closed) return;
            check(entry === null || entry.expired, "The alert ran out of time");
            check(TimerService.ringId === "" && TimerService.current !== null, "An expired alert lets the sound finish but not repeat");
            check(stopped("complete") === note.completeStopped, "The sound was not cut off: " + fileText(playedFile + ".stopped"));
            check(played("complete") === note.completePlayed + 1, "It played once: " + played("complete"));
            TimerService.stopSound();
            NotificationService.entries.slice().forEach(item => item.dismiss());
            TimerService.setSoundEnabled(false);
            // Two timers, with the expanded island's lyrics on: only the ring, at the right.
            check(TimerService.start(900, "A", false) && TimerService.start(1000, "B", false), "Start two timers");
            next();
            break;
        }
        case 40: {
            if (elapsed < 900) return;
            const readout = named(expandedLyrics, "timer-readout"), line = named(expandedLyrics, "island-lyric-line");
            check(readout.visible && line.opacity === 1 && TimerService.others === 1, "The expanded island shows lyrics and the timer");
            check(!named(readout, "timer-label").visible && !named(readout, "timer-others").visible && readout.blend === 1, "Only the ring is left, with no time and no +N");
            check(Math.abs(readout.x + readout.width - readout.parent.width) < 1.5, "The ring sits at the right edge: " + (readout.x + readout.width) + " of " + readout.parent.width);
            check(line.x + (line.width + line.contentWidth) / 2 <= readout.x, "The line ends before the ring");
            check(line.x + (line.width - line.contentWidth) / 2 >= 0, "The line stays inside");
            if (!note.expandedLyricShot) { note.expandedLyricShot = true; shoot(expandedLyricFrame, "expanded-lyrics-timer"); return; }
            TimerService.cancelAll();
            next();
            break;
        }
        case 41: {
            // Pausing: one timer from its row, or all of them like the Control Center's button.
            TimerService.cancelAll();
            check(TimerService.start(300, "Long", false) && TimerService.start(120, "Short", false), "Start two timers");
            panelLoader.active = true;
            next();
            break;
        }
        case 42: {
            if (elapsed < 400) return;
            const shortId = TimerService.leading.id;
            const pause = named(named(panelLoader.item, "timer-row-" + shortId), "timer-row-pause");
            check(TimerService.leading.label === "Short" && pause, "The shorter timer leads and has a pause button");
            check(input.mouseClick(pause, 16, 16, Qt.LeftButton, Qt.NoModifier, 0), "Press its pause button");
            check(TimerService.timers.length === 2 && TimerService.timers[1].paused && TimerService.timers[1].label === "Short", "The paused timer moves behind the running one");
            check(TimerService.leading.label === "Long" && !TimerService.leadingPaused && TimerService.running, "The island shows the timer that is still ticking");
            check(named(named(panelLoader.item, "timer-row-" + shortId), "timer-row-pause").description === "Resume timer", "The row offers to resume");
            note.frozen = TimerService.remainingSeconds(TimerService.timers[1]);
            next();
            break;
        }
        case 43: {
            if (elapsed < 1500) return;
            check(TimerService.remainingSeconds(TimerService.timers[1]) === note.frozen, "A paused timer's time stands still");
            check(fileText(stateFile).includes('"paused":true'), "The pause is saved: " + fileText(stateFile));
            TimerService.toggleAllPaused();
            check(TimerService.timers.every(timer => timer.paused) && TimerService.leadingPaused && !TimerService.running, "The Control Center button pauses every running timer");
            TimerService.toggleAllPaused();
            check(TimerService.timers.every(timer => !timer.paused) && TimerService.running && TimerService.leading.label === "Short", "Pressed again it resumes them all");
            TimerService.cancelAll();
            check(TimerService.start(1, "Blink", false), "Start a one second timer");
            TimerService.togglePause(TimerService.leading.id);
            check(TimerService.leadingPaused, "Pause it at once");
            next();
            break;
        }
        case 44: {
            if (elapsed < 1800) return;
            check(TimerService.active && TimerService.leadingPaused && !entryFor("Blink"), "A paused timer does not go off");
            TimerService.togglePause(TimerService.leading.id);
            next();
            break;
        }
        case 45: {
            if (TimerService.active || !entryFor("Blink")) return;
            check(entryFor("Blink"), "Resumed, it goes off");
            NotificationService.entries.slice().forEach(entry => entry.dismiss());
            panelLoader.active = false;
            next();
            break;
        }
        case 46: {
            // The real chain the island loads: the view host builds the compact island and the timer panel for
            // their modes, Menu routes to the panel, and it is modal like the others.
            if (elapsed < 400) return;
            IslandController.reset();
            check(IslandState.mode === IslandState.defaultMode && host.currentView && named(host.currentView, "compact-clock"), "The host shows the compact island");
            TimerService.start(300, "Host", false);
            next();
            break;
        }
        case 47: {
            if (elapsed < 800) return;
            const hostReadout = named(host.currentView, "timer-readout");
            check(hostReadout && hostReadout.visible && /^0[45]:\d\d$/.test(named(hostReadout, "timer-label").text), "The compact island the host builds shows the timer");
            check(host.currentView.implicitWidth >= 160, "The compact island keeps its width: " + host.currentView.implicitWidth);
            IslandController.openMenuEntry("timer");
            check(IslandState.mode === IslandState.timerMode && IslandState.modal, "Menu opens the timer panel, which is modal");
            next();
            break;
        }
        case 48: {
            if (elapsed < 600) return;
            check(host.currentView && host.currentView.objectName === "timer-panel", "The host builds the timer panel for its mode");
            check(host.currentView.width >= 760 && host.currentView.height < host.currentView.width, "The host shows it wide, not tall: " + host.currentView.width + "x" + host.currentView.height);
            check(named(host.currentView, "timer-running").visible && named(host.currentView, "timer-list").count === 1, "The panel lists the running timer");
            IslandController.openExpanded();
            next();
            break;
        }
        case 49: {
            if (elapsed < 600) return;
            const hostReadout = named(host.currentView, "timer-readout");
            check(hostReadout && hostReadout.visible && hostReadout.interactive, "The expanded island the host builds shows a clickable timer");
            IslandController.reset();
            TimerService.cancelAll();
            next();
            break;
        }
        case 50: {
            if (elapsed < 800 || root.shotsTaken > 0) return;
            const lyricReadout = named(lyricCompact, "timer-readout");
            check(!lyricReadout.visible && lyricCompact.timerSlot === 0, "With no timer the line has the whole island again");
            IslandController.openControlCenter();
            next();
            break;
        }
        case 51: {
            // The real Control Center the host builds: its timer card idle, running and paused.
            if (elapsed < 700) return;
            const card = named(host.currentView, "timer-control-card");
            check(card && card.title === "Timer" && card.subtitle === "Off", "The Control Center the host builds has the timer card");
            if (!note.cardIdle) { note.cardIdle = true; shoot(host, "control-center-timer-idle"); return; }
            TimerService.start(150, "", false);
            next();
            break;
        }
        case 52: {
            if (elapsed < 400) return;
            const card = named(host.currentView, "timer-control-card");
            check(card.title === "Active Timer" && card.active, "A running timer lights the card");
            if (!note.cardRunning) { note.cardRunning = true; shoot(host, "control-center-timer-running"); return; }
            check(input.mouseClick(named(card, "control-card-toggle"), 18, 18, Qt.LeftButton, Qt.NoModifier, 0) && TimerService.leadingPaused, "Pressing the lit icon pauses the timer");
            next();
            break;
        }
        case 53: {
            if (elapsed < 400) return;
            const card = named(host.currentView, "timer-control-card");
            check(/ paused$/.test(card.subtitle), "The card says it is paused: " + card.subtitle);
            if (!note.cardPaused) { note.cardPaused = true; shoot(host, "control-center-timer-paused"); return; }
            TimerService.cancelAll();
            IslandController.reset();
            next();
            break;
        }
        case 54: {
            if (elapsed < 300 || root.shotsTaken > 0) return;
            console.log("PASS: timer service, island readout, lyrics layout, alerts, Do Not Disturb, persistence and the timer panel");
            Qt.quit();
            break;
        }
        }
    }

    TestEvent { id: input }
    FloatingWindow {
        visible: true
        color: "#101010"
        implicitWidth: 1700
        implicitHeight: 1000

        Rectangle {
            id: compactFrame
            x: 20; y: 20
            width: compact.implicitWidth; height: 40
            radius: 20
            color: "black"
            DefaultView { id: compact; anchors.centerIn: parent }
        }
        Rectangle {
            id: lyricFrame
            x: 20; y: 80
            width: lyricCompact.implicitWidth; height: 40
            radius: 20
            color: "black"
            DefaultViewLyrics { id: lyricCompact; lyricsActive: true; anchors.centerIn: parent }
        }
        Rectangle {
            id: expandedFrame
            x: 20; y: 140
            width: 520; height: 75
            radius: 23
            color: "black"
            CenterSection { id: expandedSection; expanded: true; anchors.centerIn: parent }
        }
        Rectangle {
            id: expandedLyricFrame
            x: 20; y: 910
            width: 520; height: 75
            radius: 23
            color: "black"
            CenterSectionLyrics { id: expandedLyrics; expanded: true; lyricsActive: true; anchors.centerIn: parent }
        }
        // The real thing the island composes: whichever view the current mode asks for.
        ViewHost {
            id: host
            x: 840; y: 20
            monitorName: "fixture"
        }
        Rectangle {
            id: panelFrame
            x: 20; y: 230
            width: panelLoader.item ? panelLoader.item.implicitWidth : 760; height: panelLoader.item ? panelLoader.item.implicitHeight : 10
            radius: 23
            color: "black"
            Loader {
                id: panelLoader
                active: false
                anchors.fill: parent
                sourceComponent: TimerView {}
            }
        }
    }
    readonly property Item dial: panelLoader.item ? named(panelLoader.item, "timer-dial") : null

    // Keeps the popups alive without a display server for layer shells.
    NotificationWindow {
        screen: Quickshell.screens[0]
        islandTop: 10
        islandBottom: 43
        islandWidth: 160
    }

    Timer {
        interval: 40
        running: true
        repeat: true
        onTriggered: {
            try { root.tick(); }
            catch (error) { console.error("FAIL: phase " + root.phase + ": " + error); Qt.quit(); }
        }
    }
}
