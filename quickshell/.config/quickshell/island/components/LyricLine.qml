import QtQuick

import "../styles"

// One lyric line at a time. A change crossfades between two slots, so the old line is still
// fading out while the new one comes in. Lines wider than maxWidth scroll like a title.
Item {
    id: root

    property string text: ""
    property int maxWidth: 240
    property int fontSize: 14
    property color color: Theme.textPrimary

    // Which slot currently holds the visible line.
    property bool frontIsA: true
    // How wide the line being shown really is, for a host that wants to grow around it.
    readonly property real contentWidth: (frontIsA ? slotA : slotB).textWidth

    implicitWidth: maxWidth
    implicitHeight: slotA.implicitHeight

    function show(line) {
        const incoming = root.frontIsA ? slotB : slotA
        const outgoing = root.frontIsA ? slotA : slotB
        if (outgoing.text === line)
            return
        incoming.text = line
        root.frontIsA = !root.frontIsA
    }

    onTextChanged: show(text)
    Component.onCompleted: slotA.text = root.text

    ScrollingText {
        id: slotA

        anchors.horizontalCenter: parent.horizontalCenter
        maxWidth: root.maxWidth
        fontSize: root.fontSize
        color: root.color
        centered: true
        opacity: root.frontIsA ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
    }

    ScrollingText {
        id: slotB

        anchors.horizontalCenter: parent.horizontalCenter
        maxWidth: root.maxWidth
        fontSize: root.fontSize
        color: root.color
        centered: true
        opacity: root.frontIsA ? 0 : 1

        Behavior on opacity { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
    }
}
