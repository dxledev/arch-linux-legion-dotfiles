import QtQuick
import QtTest
import Quickshell
import "../../island"
import "../../core"
import "../../services"

// Clicks the Shutdown and Reboot buttons inside a full Island and answers the confirmation drawer.
// It only ever cancels: accepting would run the real systemctl poweroff/reboot.
ShellRoot {
    id: root

    function named(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const found = named(child, name);
            if (found) return found;
        }
        return null;
    }

    Timer { id: quitTimer; interval: 100; onTriggered: Qt.quit() }

    FloatingWindow {
        id: window
        visible: true
        color: "transparent"
        implicitWidth: 900
        implicitHeight: 900
        Island { id: island; x: 100; y: 10; monitorName: "HDMI-A-1" }
        TestCase {
            id: test
            name: "power-confirm"
            when: window.visible

            function click(parent, name) {
                const button = root.named(parent, name);
                verify(button, name + " missing");
                const point = button.mapToItem(null, button.width / 2, button.height / 2);
                mouseClick(test, point.x, point.y);
            }

            function waitOpen() {
                tryVerify(() => island.statusDrawerOpen && island.statusArea.reveal === 1, 3000, "drawer open");
            }

            function test_confirm() {
                ThemeService.settings = ThemeService.settings || ({});
                IslandController.setMode(IslandState.powerMenuMode, "HDMI-A-1");
                wait(600);
                const mode = IslandState.mode;
                const shutdown = root.named(island, "session-shutdown-button");
                verify(shutdown, "shutdown button missing");
                compare(shutdown.title, "Shutdown");

                click(island, "session-shutdown-button");
                verify(StatusManager.confirming, "shutdown asks first");
                compare(StatusManager.confirmTitle, "Shut down?");
                compare(StatusManager.confirmAcceptLabel, "Shutdown");
                waitOpen();
                click(island.statusArea, "confirm-cancel");
                verify(!StatusManager.confirming, "cancel resolves");
                compare(IslandState.mode, mode);

                wait(400);
                click(island, "session-reboot-button");
                verify(StatusManager.confirming, "reboot asks first");
                compare(StatusManager.confirmTitle, "Reboot?");
                // Choosing the other action replaces the question.
                click(island, "session-shutdown-button");
                compare(StatusManager.confirmTitle, "Shut down?");
                waitOpen();
                click(island.statusArea, "confirm-cancel");
                verify(!StatusManager.confirming, "cancel resolves again");
                compare(IslandState.mode, mode);
                console.log("PASS: power menu confirmation");
            }
            function cleanupTestCase() { quitTimer.start(); }
        }
    }
}
