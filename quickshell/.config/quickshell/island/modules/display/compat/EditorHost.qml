import QtQuick
import Quickshell

Item {
    id: root

    property string moduleName
    property string ipcTarget
    property bool manageIpc: false
    property bool opened: false
    property var bar: null
    property var settings: null
    property ShellScreen windowScreen: null
    readonly property QtObject controller: QtObject {
        function show(): void { root.opened = true; }
        function hide(): void { root.opened = false; }
    }
}
