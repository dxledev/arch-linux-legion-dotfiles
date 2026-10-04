import QtQuick
import "../components"

SettingsPanel {
    title: "Notifications"
    SettingSection {
        title: "Notifications"
        iconSource: "../assets/icons/bell.svg"
        SettingSlider { label: "Popup width"; setting: "notificationWidth"; minimum: 240; maximum: 800; step: 10 }
        SettingSlider { label: "Starting width (% of Island)"; setting: "notificationStartWidthPercent"; minimum: 10; maximum: 90; step: 5; suffix: " %" }
        SettingSlider { label: "Margin below Island"; setting: "notificationMargin"; maximum: 100 }
        SettingSlider { label: "Slide distance"; setting: "notificationSlideDistance"; maximum: 100 }
        SettingSlider { label: "Visible cards in stack"; setting: "notificationStackVisible"; minimum: 1; maximum: 5; suffix: "" }
        SettingSlider { label: "Stack spacing"; setting: "notificationStackSpacing"; maximum: 24 }
        SettingSlider { label: "Animation duration"; setting: "notificationAnimationDuration"; maximum: 1000; step: 25; suffix: " ms" }
        SettingSlider { label: "Default timeout"; setting: "notificationTimeout"; minimum: 1000; maximum: 15000; step: 500; suffix: " ms" }
    }
}
