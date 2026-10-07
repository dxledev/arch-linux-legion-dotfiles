import QtQuick
import qs.modules.display.compat

Item {
  id: root
  property string label: ""
  property string displayName: ""
  property string workspaces: ""
  property color foreground: Color.foreground
  property color dim: Color.dim
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  readonly property real columnGap: Math.min(Style.space(10), width * 0.04)

  width: parent ? parent.width : 0
  implicitHeight: Math.max(workspaceLabel.implicitHeight, workspaceDisplay.implicitHeight, workspaceValues.implicitHeight)

  Text {
    id: workspaceLabel
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: Math.min(parent.width * 0.34, Style.space(105))
    textFormat: Text.PlainText
    text: root.label
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    elide: Text.ElideRight
  }

  Text {
    id: workspaceValues
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: Math.min(implicitWidth, Math.max(0, (root.width - workspaceLabel.width - root.columnGap * 2) * 0.6))
    textFormat: Text.PlainText
    text: root.workspaces
    color: root.accent
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    font.bold: true
    wrapMode: Text.Wrap
    horizontalAlignment: Text.AlignRight
  }

  Text {
    id: workspaceDisplay
    anchors.left: workspaceLabel.right
    anchors.leftMargin: root.columnGap
    anchors.right: workspaceValues.left
    anchors.rightMargin: root.columnGap
    anchors.verticalCenter: parent.verticalCenter
    textFormat: Text.PlainText
    text: root.displayName
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    elide: Text.ElideRight
  }
}
