pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Fixture.Services
import "controls" as Controls
import "utils/ColourContrast.js" as Contrast

Window {
    id: root

    visible: true
    width: 1040
    height: 420
    color: "#ff101010"

    property bool inheritedUnavailable: false
    property bool captured: false

    function reading(foreground, item) {
        const background = Contrast.background(item, Colours.palette.m3surface);
        return {
            ratio: Math.round(Contrast.ratio(foreground, background) * 1000) / 1000,
            alpha: Math.round(foreground.a * 1000) / 1000,
            foreground: String(foreground),
            background: String(background)
        };
    }

    function snapshot() {
        const textBackground = Contrast.background(textButton, Colours.palette.m3surface);
        const switchIndicator = switchControl.indicator;
        const switchThumb = switchIndicator.children[1];
        const radioIndicator = radioOff.indicator;
        const radioDot = radioOn.indicator.children[1];
        const splitBody = splitButton.stateLayer.parent;
        return {
            helper: {
                whiteOnBlack: Math.round(Contrast.ratio(Qt.rgba(1, 1, 1, 1), Qt.rgba(0, 0, 0, 1)) * 1000) / 1000,
                sameColour: Math.round(Contrast.ratio(Qt.rgba(0.3333333333, 0.3333333333, 0.3333333333, 1), Qt.rgba(0.3333333333, 0.3333333333, 0.3333333333, 1)) * 1000) / 1000,
                grayOnWhite: Math.round(Contrast.ratio(Qt.rgba(0.4666666667, 0.4666666667, 0.4666666667, 1), Qt.rgba(1, 1, 1, 1)) * 1000) / 1000,
                ensured: Contrast.ratio(Colours.ensureContrast(Qt.rgba(0.333, 0.333, 0.333, 1), Qt.rgba(0.333, 0.333, 0.333, 1), 4.5), Qt.rgba(0.333, 0.333, 0.333, 1)) >= 4.5
            },
            background: {
                colour: String(textBackground),
                alphaComposite: textBackground.a === 1,
                midpoint: Math.abs(textBackground.r - 0.5) < 0.01 && Math.abs(textBackground.g - 0.5) < 0.01 && Math.abs(textBackground.b - 0.5) < 0.01
            },
            buttons: {
                filledOff: reading(filledButton.onColour, filledButton),
                tonalOff: reading(tonalButton.onColour, tonalButton),
                textOff: reading(textButton.onColour, textButton),
                customOff: reading(customButton.onColour, customButton),
                lockOff: reading(lockButton.onColour, lockButton),
                filledChecked: reading(filledButton.onColour, filledButton),
                tonalChecked: reading(tonalButton.onColour, tonalButton),
                textChecked: reading(textButton.onColour, textButton),
                lockChecked: reading(lockButton.onColour, lockButton),
                filledDisabled: reading(filledButton.onColour, filledButton),
                inheritedDisabled: {
                    unavailable: inheritedButton.unavailable,
                    ratio: reading(inheritedButton.onColour, inheritedButton).ratio,
                    alpha: reading(inheritedButton.onColour, inheritedButton).alpha
                }
            },
            split: {
                enabled: reading(splitButton.label.color, splitBody),
                disabled: reading(splitButton.label.color, splitBody)
            },
            switch: {
                off: {
                    trackRatio: reading(switchControl.trackColour, switchControl).ratio,
                    thumbRatio: reading(switchThumb.color, switchIndicator).ratio,
                    glyphRatio: reading(switchControl.glyphColour, switchThumb).ratio
                },
                on: {
                    trackRatio: reading(switchControl.trackColour, switchControl).ratio,
                    thumbRatio: reading(switchThumb.color, switchIndicator).ratio,
                    glyphRatio: reading(switchControl.glyphColour, switchThumb).ratio
                },
                disabled: {
                    trackRatio: reading(switchControl.trackColour, switchControl).ratio,
                    thumbRatio: reading(switchThumb.color, switchIndicator).ratio,
                    glyphRatio: reading(switchControl.glyphColour, switchThumb).ratio
                }
            },
            radio: {
                off: {
                    ringRatio: reading(radioIndicator.border.color, radioIndicator).ratio
                },
                on: {
                    ringRatio: reading(radioOn.indicator.border.color, radioOn.indicator).ratio,
                    dotRatio: reading(radioDot.color, radioOn.indicator).ratio
                },
                disabled: {
                    unavailable: radioOff.unavailable,
                    textRatio: reading(radioOff.contentItem.color, radioOff).ratio
                }
            },
            slider: {
                enabled: {
                    fgRatio: Math.round(Contrast.ratio(enabledSlider.contrastFgColour, Qt.tint(Colours.backgroundFor(enabledSlider), enabledSlider.bgColour)) * 1000) / 1000,
                    bgRatio: Math.round(Contrast.ratio(enabledSlider.bgColour, Colours.backgroundFor(enabledSlider)) * 1000) / 1000
                },
                disabled: {
                    fgRatio: Math.round(Contrast.ratio(inheritedSlider.contrastFgColour, Qt.tint(Colours.backgroundFor(inheritedSlider), inheritedSlider.bgColour)) * 1000) / 1000,
                    bgRatio: Math.round(Contrast.ratio(inheritedSlider.bgColour, Colours.backgroundFor(inheritedSlider)) * 1000) / 1000
                }
            },
            theme: {
                background: String(themeButton.activeColour),
                foreground: String(themeButton.onColour),
                ratio: reading(themeButton.onColour, themeButton).ratio,
                bindingChanged: !Qt.colorEqual(themeButton.activeColour, "#ff555555")
            }
        };
    }

    Rectangle {
        id: baseSurface

        anchors.fill: parent
        color: Colours.palette.m3surface

        Controls.ButtonBase {
            id: filledButton

            x: 24
            y: 30
            implicitWidth: 145
            implicitHeight: 48
            activeColour: "#ff444444"
            inactiveColour: "#ff444444"
            activeOnColour: "#ff444444"
            inactiveOnColour: "#ff444444"
        }

        Text {
            anchors.centerIn: filledButton
            text: "Filled"
            color: filledButton.onColour
        }

        Controls.ButtonBase {
            id: tonalButton

            x: 190
            y: 30
            type: 1
            implicitWidth: 145
            implicitHeight: 48
            activeColour: "#ff646464"
            inactiveColour: "#ff646464"
            activeOnColour: "#ff646464"
            inactiveOnColour: "#ff646464"
        }

        Text {
            anchors.centerIn: tonalButton
            text: "Tonal"
            color: tonalButton.onColour
        }

        Rectangle {
            id: translucentSurface

            x: 356
            y: 22
            width: 160
            height: 64
            color: "#80eeeeee"

            Controls.ButtonBase {
                id: textButton

                x: 8
                y: 8
                type: 2
                implicitWidth: 144
                implicitHeight: 48
                activeColour: "#ff555555"
                inactiveColour: "#ff555555"
                activeOnColour: "#ff555555"
                inactiveOnColour: "#ff555555"
            }

            Text {
                anchors.centerIn: textButton
                text: "Text"
                color: textButton.onColour
            }
        }

        Controls.ButtonBase {
            id: customButton

            x: 536
            y: 30
            implicitWidth: 145
            implicitHeight: 48
            activeColour: "#ff525252"
            inactiveColour: "#ff525252"
            activeOnColour: "#ff525252"
            inactiveOnColour: "#ff525252"
        }

        Text {
            anchors.centerIn: customButton
            text: "Custom"
            color: customButton.onColour
        }

        Controls.LockButtonBase {
            id: lockButton

            x: 700
            y: 30
            implicitWidth: 145
            implicitHeight: 48
            activeColour: "#ff595959"
            inactiveColour: "#ff595959"
            activeOnColour: "#ff595959"
            inactiveOnColour: "#ff595959"
        }

        Text {
            anchors.centerIn: lockButton
            text: "Lock"
            color: lockButton.onColour
        }

        Controls.ButtonBase {
            id: themeButton

            x: 864
            y: 30
            implicitWidth: 145
            implicitHeight: 48
            activeColour: Colours.palette.m3primary
            inactiveColour: Colours.palette.m3primary
            activeOnColour: Colours.palette.m3primary
            inactiveOnColour: Colours.palette.m3primary
        }

        Text {
            anchors.centerIn: themeButton
            text: "Theme"
            color: themeButton.onColour
        }

        Controls.SplitButton {
            id: splitButton

            x: 24
            y: 132
            fallbackText: "Split"
            colour: "#ff414141"
            textColour: "#ff414141"
            minLeftWidth: 130
        }

        Controls.StyledSwitch {
            id: switchControl

            x: 24
            y: 218
            checked: false
        }

        Item {
            x: 200
            y: 208
            width: 180
            height: 80
            enabled: !root.inheritedUnavailable

            Controls.StyledRadioButton {
                id: radioOff

                x: 0
                y: 0
                text: "Radio off"
            }

            Controls.StyledRadioButton {
                id: radioOn

                x: 0
                y: 38
                checked: true
                text: "Radio on"
            }
        }

        Controls.StyledSlider {
            id: enabledSlider

            x: 440
            y: 230
            width: 200
            height: 24
        }

        Item {
            id: inheritedGroup

            x: 24
            y: 318
            width: 900
            height: 80
            enabled: !root.inheritedUnavailable

            Controls.ButtonBase {
                id: inheritedButton

                x: 0
                y: 0
                implicitWidth: 145
                implicitHeight: 48
                activeColour: "#ff474747"
                inactiveColour: "#ff474747"
                activeOnColour: "#ff474747"
                inactiveOnColour: "#ff474747"
            }

            Controls.StyledSlider {
                id: inheritedSlider

                x: 450
                y: 12
                width: 200
                height: 24
            }
        }
    }

    IpcHandler {
        target: "colourContrastTest"

        function snapshot(): string {
            return JSON.stringify(root.snapshot());
        }

        function setChecked(): void {
            for (const button of [filledButton, tonalButton, textButton, lockButton])
                button.checked = true;
            switchControl.checked = true;
        }

        function setUnavailable(): void {
            filledButton.disabled = true;
            splitButton.disabled = true;
            switchControl.disabled = true;
            root.inheritedUnavailable = true;
        }

        function reloadTheme(): void {
            Colours.palette.m3surface = "#fff4f0e8";
            Colours.palette.m3primary = "#ffcccccc";
            Colours.palette.m3onSurface = "#ff222222";
        }

        function capture(path: string): void {
            root.contentItem.grabToImage(result => {
                root.captured = result.saveToFile(path);
            });
        }
    }
}
