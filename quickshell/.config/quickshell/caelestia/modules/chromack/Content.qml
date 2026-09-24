import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts

FocusScope {
    id: root
    objectName: "chromackContent"
    Rectangle {
        anchors.fill: parent
        radius: Style.panelRadius
        color: Style.panel
    }
    Keys.onEscapePressed: event => {
        ChromackState.close(false);
        event.accepted = true;
    }
    MouseArea {
        anchors.fill: parent
        onPressed: root.forceActiveFocus()
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.padding
        spacing: Style.gap + 4
        Header {
            Layout.fillWidth: true
        }
        Label {
            Layout.fillWidth: true
            visible: ChromackState.errorMessage.length > 0
            text: ChromackState.errorMessage
            color: Style.danger
            wrapMode: Text.WordWrap
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: -Style.tabOverlap
            RowLayout {
                Layout.fillWidth: true
                spacing: 0
                Repeater {
                    model: ["Color Picker", "Shade", "Palette", "Theory"]
                    Button {
                        required property string modelData
                        required property int index
                        text: modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: 30
                        tabButton: true
                        tabSelected: ChromackState.tab === index
                        onClicked: ChromackState.tab = index
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Style.content
                bottomLeftRadius: Style.contentRadius
                bottomRightRadius: Style.contentRadius
                Flickable {
                    id: scroll
                    anchors.fill: parent
                    anchors.margins: 10
                    clip: true
                    contentWidth: width
                    contentHeight: page.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick
                    QQC.ScrollBar.vertical: QQC.ScrollBar {
                        policy: ChromackState.data.scrollbar === "none" ? QQC.ScrollBar.AlwaysOff : ChromackState.data.scrollbar === "always" ? QQC.ScrollBar.AlwaysOn : QQC.ScrollBar.AsNeeded
                    }
                    Loader {
                        id: page
                        width: scroll.width
                        sourceComponent: [pickerPage, shadesPage, palettePage, theoryPage][ChromackState.tab]
                        onLoaded: scroll.contentY = 0
                    }
                }
            }
        }
    }
    Component {
        id: pickerPage
        Picker {}
    }
    Component {
        id: shadesPage
        Shades {}
    }
    Component {
        id: palettePage
        PaletteTab {}
    }
    Component {
        id: theoryPage
        Theory {}
    }
}
