import QtQuick
import Caelestia.Config
import qs.components
import qs.services

LockButtonBase {
    id: root

    property alias icon: label.text
    readonly property alias label: label

    font: Tokens.font.icon.medium
    padding: type === LockButtonBase.Text ? Tokens.padding.extraSmall / 2 : Tokens.padding.small
    activeColour: type === LockButtonBase.Filled ? Colours.palette.m3primary : Colours.palette.m3secondary
    inactiveColour: {
        if (!isToggle && type === LockButtonBase.Filled)
            return Colours.palette.m3primary;
        return type === LockButtonBase.Filled ? Colours.tPalette.m3surfaceContainer : Colours.palette.m3secondaryContainer;
    }
    activeOnColour: type === LockButtonBase.Filled ? Colours.palette.m3onPrimary : type === LockButtonBase.Tonal ? Colours.palette.m3onSecondary : Colours.palette.m3primary
    inactiveOnColour: {
        if (!isToggle && type === LockButtonBase.Filled)
            return Colours.palette.m3onPrimary;
        return type === LockButtonBase.Tonal ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant;
    }

    implicitWidth: implicitHeight
    implicitHeight: {
        const height = label.implicitHeight + padding * 2;
        return height % 2 === 0 ? height : height + 1;
    }

    MaterialIcon {
        id: label

        anchors.centerIn: parent
        anchors.verticalCenterOffset: 1
        color: root.onColour
        fontStyle: root.font
        fill: !root.isToggle || root.internalChecked ? 1 : 0

        Behavior on fill {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
