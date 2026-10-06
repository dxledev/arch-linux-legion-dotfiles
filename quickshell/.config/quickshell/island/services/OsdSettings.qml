pragma Singleton
import QtQuick
import Quickshell
import "../styles"

Singleton {
    readonly property string fontFamily: ThemeService.settings.osdInheritUiFont
        ? Theme.uiFontFamily : ThemeService.settings.osdFontFamily || "JetBrainsMono Nerd Font"
    readonly property int fontSize: ThemeService.settings.osdFontSize ?? 18
    readonly property bool fontBold: ThemeService.settings.osdFontBold ?? true
    readonly property int iconSize: ThemeService.settings.osdIconSize ?? 18
    readonly property int sliderWidth: ThemeService.settings.osdSliderWidth ?? 180
    readonly property int sliderHeight: ThemeService.settings.osdSliderHeight ?? 6
    readonly property real sliderRadius: Math.min(sliderHeight / 2, ThemeService.settings.osdSliderRadius ?? 3)
    readonly property int sliderAnimationDuration: ThemeService.settings.osdSliderAnimationDuration ?? 180
    readonly property int animationDuration: ThemeService.settings.osdAnimationDuration ?? 120
    readonly property int timeout: ThemeService.settings.osdTimeout ?? 1800
    readonly property bool showPercentage: ThemeService.settings.osdShowPercentage ?? true
    readonly property int rowHeight: Math.max(33, fontSize + 12, iconSize + 12, sliderHeight + 12)
}
