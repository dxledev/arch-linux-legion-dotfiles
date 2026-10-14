pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../components"
import "../core"
import "../services"
import "../styles"
import "../services/CalendarEvents.js" as Events

// Month calendar with holidays and global events, beside the selected day's events and the
// Dashboard's tasks. Opens on the current month with today selected.
FocusScope {
    id: root
    objectName: "calendar-view"

    readonly property int panelPadding: 24
    readonly property int cellWidth: 56
    readonly property int cellHeight: 50
    readonly property int gridWidth: cellWidth * 7
    readonly property int sidePaneWidth: 320
    readonly property int cardPadding: 14
    readonly property var kindColors: ({
        holiday: Theme.warning, observance: "#F472B6", global: "#38BDF8", astro: "#A78BFA", task: Theme.success
    })
    readonly property var kindLabels: ({
        holiday: "Holiday", observance: "Observance", global: "Global", astro: "Sky", task: "Task due"
    })

    readonly property date now: clock.date
    readonly property string todayKey: DashboardTasksService.dateKey(now)
    property date selectedDate: new Date(now.getFullYear(), now.getMonth(), now.getDate())
    readonly property int viewYear: selectedDate.getFullYear()
    readonly property int viewMonth: selectedDate.getMonth()
    readonly property string selectedKey: DashboardTasksService.dateKey(selectedDate)
    readonly property int firstWeekday: new Date(viewYear, viewMonth, 1).getDay()
    readonly property var selectedEvents: Events.eventsFor(viewYear, viewMonth, selectedDate.getDate())
    readonly property var selectedTasks: DashboardTasksService.tasksFor(selectedKey)
    readonly property int doneCount: selectedTasks.filter(task => task.done).length
    // "once" files the task under the selected date, "daily" and "weekly" create a recurrence rule.
    property string newRecurrence: "date"

    implicitWidth: panelPadding * 2 + gridWidth + cardPadding * 2 + 24 + sidePaneWidth
    implicitHeight: panelPadding * 2 + content.implicitHeight
    // A fresh motivational quote each time the panel opens (QuoteService steps on every take()).
    property var quote: null
    readonly property string quoteText: quote ? "\u201C" + quote.q + "\u201D  \u2014 " + quote.a : ""

    Component.onCompleted: {
        quote = QuoteService.take()
        forceActiveFocus()
    }

    function select(date) {
        selectedDate = new Date(date.getFullYear(), date.getMonth(), date.getDate())
    }

    function shiftDays(days) {
        select(new Date(viewYear, viewMonth, selectedDate.getDate() + days))
    }

    function shiftMonths(months) {
        const target = new Date(viewYear, viewMonth + months, 1)
        const lastDay = new Date(target.getFullYear(), target.getMonth() + 1, 0).getDate()
        select(new Date(target.getFullYear(), target.getMonth(), Math.min(selectedDate.getDate(), lastDay)))
    }

    function goToday() { select(now) }

    function daysFromToday(date) {
        const start = new Date(now.getFullYear(), now.getMonth(), now.getDate())
        return Math.round((date.getTime() - start.getTime()) / 86400000)
    }

    function relativeLabel(date) {
        const days = daysFromToday(date)
        if (days === 0) return "Today"
        if (days === 1) return "Tomorrow"
        if (days === -1) return "Yesterday"
        return days > 0 ? "In " + days + " days" : Math.abs(days) + " days ago"
    }

    function submitTask() {
        const text = taskField.text.trim()
        if (!text) return
        const weekday = DashboardTasksService.weekdayNames[selectedDate.getDay()]
        const value = newRecurrence === "daily" ? "daily" : newRecurrence === "weekly" ? weekday : selectedKey
        if (DashboardTasksService.add(text, newRecurrence, value)) {
            taskField.clear()
            newRecurrence = "date"
        }
    }

    function dotColorsFor(events, key) {
        const colors = []
        for (const event of events) {
            const color = kindColors[event.kind]
            if (!colors.includes(color)) colors.push(color)
        }
        if (DashboardTasksService.dueCountFor(key) > 0) colors.push(kindColors.task)
        return colors.slice(0, 4)
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Keys.onEscapePressed: IslandController.reset()
    Keys.onPressed: event => {
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) return
        let handled = true
        switch (event.key) {
        case Qt.Key_Left: root.shiftDays(-1); break
        case Qt.Key_Right: root.shiftDays(1); break
        case Qt.Key_Up: root.shiftDays(-7); break
        case Qt.Key_Down: root.shiftDays(7); break
        case Qt.Key_PageUp: root.shiftMonths(-1); break
        case Qt.Key_PageDown: root.shiftMonths(1); break
        case Qt.Key_Home:
        case Qt.Key_T: root.goToday(); break
        case Qt.Key_N:
        case Qt.Key_A: taskField.forceActiveFocus(); break
        default: handled = false
        }
        event.accepted = handled
    }

    // Sits in the header's free space, between the title and the close button: right-aligned beside the
    // close button when it fits, scrolling when long.
    UiText {
        id: titleMeasure
        visible: false
        text: "Calendar"
        font.pixelSize: 25
        font.weight: Font.DemiBold
    }
    ScrollingText {
        id: quoteLine
        objectName: "calendar-quote"
        readonly property int startX: root.panelPadding + 52 + titleMeasure.implicitWidth + 32
        readonly property int endX: root.width - root.panelPadding - 36 - 20
        x: startX
        y: root.panelPadding + (48 - height) / 2
        maxWidth: Math.max(0, endX - startX)
        rightAligned: true
        visible: maxWidth > 80 && text.length > 0
        text: root.quoteText
        fontSize: 13
        bold: false
        color: Theme.textSecondary
        opacity: 0
        Component.onCompleted: opacity = 1
        Behavior on opacity { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
        Accessible.role: Accessible.StaticText
        Accessible.name: root.quoteText
    }

    Column {
        id: content
        x: root.panelPadding
        y: root.panelPadding
        width: parent.width - root.panelPadding * 2
        spacing: 14

        PanelHeader {
            title: "Calendar"
            onBack: IslandController.backFromCalendar()
        }

        Row {
            width: parent.width
            spacing: 24

            Rectangle {
                id: monthCard
                objectName: "calendar-month-card"
                width: root.gridWidth + root.cardPadding * 2
                height: monthColumn.height + root.cardPadding * 2
                radius: 22
                color: Theme.card

                Column {
                    id: monthColumn
                    x: root.cardPadding
                    y: root.cardPadding
                    width: root.gridWidth
                    spacing: 8

                    Item {
                        width: parent.width
                        height: 44

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8
                            UiText {
                                text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM")
                                color: Theme.textPrimary
                                font.pixelSize: 28
                                font.weight: Font.DemiBold
                            }
                            UiText {
                                id: yearLabel
                                text: root.viewYear
                                color: Theme.textSecondary
                                font.pixelSize: 28
                                font.weight: Font.Light
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            Rectangle {
                                id: todayButton
                                anchors.verticalCenter: parent.verticalCenter
                                width: todayText.implicitWidth + 24
                                height: 30
                                radius: 15
                                visible: opacity > 0
                                opacity: root.selectedKey === root.todayKey ? 0 : 1
                                color: todayTap.pressed ? Theme.buttonPressed : todayHover.hovered ? Theme.surfaceVariant : Theme.surface
                                Behavior on opacity { NumberAnimation { duration: Theme.animationFast } }
                                Behavior on color { ColorAnimation { duration: Theme.animationFast } }
                                Accessible.role: Accessible.Button
                                Accessible.name: "Go to today"
                                UiText {
                                    id: todayText
                                    anchors.centerIn: parent
                                    text: "Today"
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: Theme.textPrimary
                                }
                                HoverHandler { id: todayHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler { id: todayTap; onTapped: root.goToday() }
                            }
                            IconButton {
                                iconSource: "../assets/icons/chevron-left.svg"
                                description: "Previous month"
                                onClicked: root.shiftMonths(-1)
                            }
                            IconButton {
                                iconSource: "../assets/icons/chevron-right.svg"
                                description: "Next month"
                                onClicked: root.shiftMonths(1)
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        Repeater {
                            model: 7
                            UiText {
                                required property int index
                                width: root.cellWidth
                                height: 22
                                text: Qt.locale().dayName(index, Locale.ShortFormat).slice(0, 3).toUpperCase()
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1
                                color: index === 0 || index === 6 ? Theme.textMuted : Theme.textSecondary
                            }
                        }
                    }

                    Item {
                        id: gridFrame
                        width: parent.width
                        height: root.cellHeight * 6

                        // Hairlines between days, under the cells so out-of-month fading doesn't touch them.
                        Repeater {
                            model: 5
                            Rectangle {
                                required property int index
                                objectName: "calendar-separator-row"
                                x: 6
                                y: root.cellHeight * (index + 1) - 0.5
                                width: gridFrame.width - 12
                                height: 1
                                color: Theme.border
                                opacity: 0.45
                            }
                        }
                        Repeater {
                            model: 6
                            Rectangle {
                                required property int index
                                objectName: "calendar-separator-column"
                                x: root.cellWidth * (index + 1) - 0.5
                                y: 6
                                width: 1
                                height: gridFrame.height - 12
                                color: Theme.border
                                opacity: 0.45
                            }
                        }
                        Grid {
                            id: grid
                            objectName: "calendar-grid"
                            columns: 7
                            width: parent.width

                            Repeater {
                                model: 42
                                CalendarDayCell {
                                    id: cell
                                    required property int index
                                    readonly property date day: new Date(root.viewYear, root.viewMonth, 1 - root.firstWeekday + index)
                                    readonly property string key: DashboardTasksService.dateKey(day)
                                    readonly property var events: Events.eventsFor(day.getFullYear(), day.getMonth(), day.getDate())
                                    objectName: "calendar-day-" + key
                                    width: root.cellWidth
                                    height: root.cellHeight
                                    cellDate: day
                                    inMonth: day.getMonth() === root.viewMonth
                                    today: key === root.todayKey
                                    selected: key === root.selectedKey
                                    holiday: events.length > 0 && events[0].kind === "holiday"
                                    dotColors: root.dotColorsFor(events, key)
                                    description: Qt.formatDate(day, "dddd, MMMM d") + (events.length ? ", " + events.map(event => event.title).join(", ") : "")
                                    onClicked: root.select(day)
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 2 }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 14
                        Repeater {
                            model: ["holiday", "observance", "global", "astro", "task"]
                            Row {
                                required property string modelData
                                spacing: 5
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: root.kindColors[parent.modelData]
                                }
                                UiText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.kindLabels[parent.modelData]
                                    font.pixelSize: 11
                                    color: Theme.textMuted
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: sidePane
                objectName: "calendar-day-pane"
                width: root.sidePaneWidth
                height: monthCard.height
                radius: 22
                color: Theme.surface

                Column {
                    id: dayHeader
                    x: 20
                    y: 18
                    width: parent.width - 40
                    spacing: 2
                    UiText {
                        text: root.relativeLabel(root.selectedDate).toUpperCase()
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.2
                        color: root.selectedKey === root.todayKey ? Theme.accent : Theme.textMuted
                    }
                    UiText {
                        objectName: "calendar-day-title"
                        width: parent.width
                        text: Qt.formatDate(root.selectedDate, "dddd")
                        elide: Text.ElideRight
                        font.pixelSize: 26
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                    }
                    UiText {
                        text: Qt.formatDate(root.selectedDate, "MMMM d, yyyy")
                        font.pixelSize: 13
                        color: Theme.textSecondary
                    }
                }

                Flickable {
                    id: body
                    x: 12
                    y: dayHeader.y + dayHeader.height + 12
                    width: parent.width - 24
                    height: addRow.y - 10 - y
                    clip: true
                    contentWidth: width
                    contentHeight: bodyColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick

                    Column {
                        id: bodyColumn
                        width: body.width
                        spacing: 4

                        UiText {
                            x: 8
                            text: "EVENTS"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.2
                            color: Theme.textMuted
                        }

                        Repeater {
                            model: root.selectedEvents
                            Item {
                                id: eventRow
                                required property var modelData
                                objectName: "calendar-event-row"
                                width: bodyColumn.width
                                height: Math.max(30, eventTitle.implicitHeight + 10)
                                Rectangle {
                                    x: 8
                                    y: (parent.height - height) / 2
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: root.kindColors[eventRow.modelData.kind]
                                }
                                UiText {
                                    id: eventTitle
                                    x: 26
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 26 - (eventTime.visible ? eventTime.width + 16 : 8)
                                    text: eventRow.modelData.title
                                    textFormat: Text.PlainText
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    font.pixelSize: 13
                                    color: Theme.textPrimary
                                }
                                UiText {
                                    id: eventTime
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: eventRow.modelData.time.length > 0
                                    text: eventRow.modelData.time
                                    font.pixelSize: 11
                                    color: Theme.textMuted
                                }
                            }
                        }

                        UiText {
                            id: nothingLabel
                            objectName: "calendar-no-events"
                            x: 8
                            width: bodyColumn.width - 16
                            visible: root.selectedEvents.length === 0
                            readonly property var next: Events.upcoming(new Date(root.viewYear, root.viewMonth, root.selectedDate.getDate() + 1), 1, ["holiday", "observance", "global"])[0]
                            text: next ? "No events. Next: " + next.title + ", " + Qt.formatDate(next.date, "MMM d") : "No holidays or events"
                            wrapMode: Text.WordWrap
                            font.pixelSize: 12
                            color: Theme.textMuted
                        }

                        Item { width: 1; height: 10 }

                        Item {
                            width: bodyColumn.width
                            height: tasksHeading.implicitHeight
                            UiText {
                                id: tasksHeading
                                x: 8
                                text: "TASKS"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.2
                                color: Theme.textMuted
                            }
                            UiText {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: tasksHeading.verticalCenter
                                visible: root.selectedTasks.length > 0
                                text: root.doneCount + " of " + root.selectedTasks.length + " done"
                                font.pixelSize: 11
                                color: Theme.textMuted
                            }
                        }

                        Repeater {
                            model: root.selectedTasks
                            CalendarTaskRow {
                                required property var modelData
                                objectName: "calendar-task-row"
                                width: bodyColumn.width
                                task: modelData
                                onToggled: DashboardTasksService.setDone(root.selectedKey, modelData.id, !modelData.done)
                                onRemoved: DashboardTasksService.remove(modelData)
                            }
                        }

                        UiText {
                            objectName: "calendar-no-tasks"
                            x: 8
                            width: bodyColumn.width - 16
                            visible: root.selectedTasks.length === 0
                            text: DashboardTasksService.error || (DashboardTasksService.ready ? "No tasks. Add one below." : "Loading tasks…")
                            wrapMode: Text.WordWrap
                            font.pixelSize: 12
                            color: DashboardTasksService.error ? Theme.danger : Theme.textMuted
                        }

                        UiText {
                            x: 8
                            width: bodyColumn.width - 16
                            visible: DashboardTasksService.actionError.length > 0
                            text: DashboardTasksService.actionError
                            wrapMode: Text.WordWrap
                            font.pixelSize: 11
                            color: Theme.danger
                        }
                    }
                }

                Column {
                    id: addRow
                    x: 12
                    y: parent.height - height - 12
                    width: parent.width - 24
                    spacing: 8

                    Row {
                        spacing: 6
                        x: 4
                        Repeater {
                            model: [
                                { key: "date", label: "Once" },
                                { key: "daily", label: "Daily" },
                                { key: "weekly", label: "Weekly" }
                            ]
                            Rectangle {
                                id: chip
                                required property var modelData
                                readonly property bool active: root.newRecurrence === modelData.key
                                objectName: "calendar-recurrence-" + modelData.key
                                width: chipText.implicitWidth + 20
                                height: 24
                                radius: 12
                                color: active ? Theme.accent : chipHover.hovered ? Theme.surfaceVariant : Theme.card
                                Behavior on color { ColorAnimation { duration: Theme.animationFast } }
                                Accessible.role: Accessible.RadioButton
                                Accessible.name: modelData.label
                                Accessible.checked: active
                                UiText {
                                    id: chipText
                                    anchors.centerIn: parent
                                    text: chip.modelData.label
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: chip.active ? Theme.background : Theme.textSecondary
                                }
                                HoverHandler { id: chipHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: root.newRecurrence = chip.modelData.key }
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 40

                        SearchField {
                            id: taskField
                            objectName: "calendar-task-field"
                            anchors.left: parent.left
                            anchors.right: addButton.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            enabled: DashboardTasksService.ready && !DashboardTasksService.error
                            placeholderText: root.newRecurrence === "daily" ? "Add a daily task…"
                                : root.newRecurrence === "weekly" ? "Add a task for every " + Qt.formatDate(root.selectedDate, "dddd") + "…"
                                : "Add a task for this day…"
                            maximumLength: 200
                            onAccepted: root.submitTask()
                            Keys.onEscapePressed: event => {
                                event.accepted = true
                                root.forceActiveFocus()
                            }
                            Keys.onUpPressed: event => event.accepted = true
                            onNavigateDown: root.forceActiveFocus()
                        }

                        IconButton {
                            id: addButton
                            objectName: "calendar-task-add"
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            enabled: taskField.enabled && taskField.text.trim().length > 0
                            opacity: enabled ? 1 : 0.45
                            iconSource: "../assets/icons/check.svg"
                            iconColor: Theme.accent
                            description: "Add task"
                            onClicked: root.submitTask()
                        }
                    }
                }
            }
        }
    }
}
