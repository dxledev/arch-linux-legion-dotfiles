import QtQuick
import QtTest
import Quickshell
import "../../lock"
import "../../views"
import "../../services"

ShellRoot {
    id: root
    property int phase: 0
    property int elapsed: 0
    property int successes: 0
    property int unlockCycles: 0
    property bool captured: false

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

    function tick() {
        elapsed += 40;
        if (elapsed > 10000) throw new Error("Timed out in phase " + phase);
        const password = named(view, "lock-password");
        check(password.enabled && !password.readOnly, "Password input remains editable throughout authentication");
        check(named(view, "lock-submit").enabled, "Unlock arrow remains available throughout authentication");
        switch (phase) {
        case 0:
            if (!ThemeService.ready || elapsed < 300) return;
            check(password.echoMode === TextInput.Password, "Password remains masked");
            check(named(view, "lock-indicator") !== null, "Header keeps the lock icon");
            check(!named(view, "lock-background").hasSnapshot, "Unavailable desktop capture uses the fallback");
            check(named(settings, "setting-slider-lockClockSize") !== null, "Lock settings are available");
            auth.buffer = "discarded";
            auth.submit();
            check(!auth.busy && successes === 0, "No authentication outside a secure lock");
            auth.locked = true;
            check(auth.buffer === "", "Entering a lock clears prior input");
            if (Quickshell.env("ISLAND_TEST_SCREENSHOT")) {
                view.grabToImage(result => {
                    check(result.saveToFile(Quickshell.env("ISLAND_TEST_SCREENSHOT")), "Save preview");
                    root.captured = true;
                });
            } else captured = true;
            view.focusInput();
            next();
            break;
        case 1:
            if (!captured) return;
            events.keyClick(Qt.Key_A);
            events.keyClick(Qt.Key_B);
            check(auth.buffer === "ab", "Typing updates shared authentication input");
            check(named(otherView, "lock-password").text === "ab", "Other displays share password input");
            events.keyClick(Qt.Key_Escape);
            check(auth.buffer === "" && auth.locked && successes === 0, "Escape clears without unlocking");
            events.keyClick(Qt.Key_A);
            events.keyClick(Qt.Key_Return);
            next();
            break;
        case 2:
            if (auth.busy || !auth.error) return;
            check(successes === 0 && auth.locked, "Failed PAM authentication never unlocks");
            check(auth.buffer === "" && password.text === "", "Failed authentication clears input on every display");
            check(!auth.canSubmit, "Failed attempts have a retry delay");
            next();
            break;
        case 3:
            if (!auth.canSubmit) return;
            auth.config = "permit";
            view.focusInput();
            for (const key of [Qt.Key_T, Qt.Key_E, Qt.Key_S, Qt.Key_T, Qt.Key_Minus, Qt.Key_O, Qt.Key_N, Qt.Key_L, Qt.Key_Y])
                events.keyClick(key);
            check(auth.buffer === "test-only", "Typing after a failed attempt replaces the cleared password");
            events.keyClick(Qt.Key_Return);
            next();
            break;
        case 4:
            if (auth.busy || successes === 0) return;
            check(successes === unlockCycles + 1 && auth.buffer === "", "Each successful password authenticates exactly once");
            check(!auth.locked, "Successful authentication clears the lock state");
            auth.buffer = "test-only";
            auth.submit();
            check(!auth.busy && successes === unlockCycles + 1, "An unlocked session does not authenticate again");
            auth.buffer = "discarded";
            auth.reset();
            check(auth.buffer === "" && auth.error === "", "Reset clears transient state");
            unlockCycles++;
            if (unlockCycles < 8) {
                auth.locked = true;
                phase = 3;
                elapsed = 0;
                break;
            }
            ThemeService.setSetting("clock12Hour", true);
            ThemeService.setSetting("lockClockSize", 128);
            next();
            break;
        case 5:
            if (ThemeService.busy || ThemeService.settings.lockClockSize !== 128) return;
            check(named(view, "lock-clock").font.pixelSize === 128, "Saved clock size updates the view");
            check(/AM|PM/.test(named(view, "lock-date").text), "12-hour clock includes the meridian");
            ThemeService.setSetting("clock12Hour", false);
            next();
            break;
        case 6:
            if (ThemeService.busy || ThemeService.settings.clock12Hour) return;
            check(!/AM|PM/.test(named(view, "lock-date").text), "24-hour clock omits the meridian");
            window.width = 400;
            window.height = 600;
            next();
            break;
        case 7:
            check(view.passwordField.width <= view.width - 48, "Password field fits a small display");
            console.log("PASS: masked and shared input, Escape, PAM rejection, eight first-attempt unlock cycles, retry delay, password clearing, saved settings, time format, and small displays");
            Qt.quit();
        }
    }

    LockAuth {
        id: auth
        configDirectory: Quickshell.env("ISLAND_TEST_PAM_DIRECTORY")
        config: "deny"
        retryDelay: 250
        onAuthenticated: {
            root.successes++;
            locked = false;
        }
    }

    FloatingWindow {
        id: window
        visible: true
        width: 1280
        height: 800
        color: "#191724"
        LockView { id: view; anchors.fill: parent; auth: auth }
        LockView { id: otherView; visible: false; width: 1280; height: 800; auth: auth }
        LockSettingsView { id: settings; visible: false }
    }

    TestCase { id: events; when: false }
    Timer {
        interval: 40
        running: true
        repeat: true
        onTriggered: {
            try { root.tick(); }
            catch (error) { console.error("FAIL: " + error); Qt.quit(); }
        }
    }
}
