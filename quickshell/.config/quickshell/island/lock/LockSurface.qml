import QtQuick
import Quickshell.Wayland
import "../styles"

WlSessionLockSurface {
    id: root
    required property LockAuth auth
    color: Theme.background

    LockView {
        anchors.fill: parent
        auth: root.auth
        screen: root.screen
    }
}
