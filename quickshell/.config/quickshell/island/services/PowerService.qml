pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    Process {
        id: commandProcess
    }

    function run(cmd) {
        commandProcess.command = cmd
        commandProcess.running = true
    }

    function lock() {
        LockService.lock()
    }

    function logout() {
        if (Compositor.niri) {
            run([NiriService.binary, "msg", "action", "quit", "--skip-confirmation"])
            return
        }
        run([
            "hyprctl",
            "dispatch",
            "exit"
        ])
    }

    function suspend() {
        run([
            "systemctl",
            "suspend"
        ])
    }

    function reboot() {
        run([
            "systemctl",
            "reboot"
        ])
    }

    function poweroff() {
        run([
            "systemctl",
            "poweroff"
        ])
    }
}
