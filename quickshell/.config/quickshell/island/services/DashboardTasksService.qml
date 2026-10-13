pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The Dashboard's task list (~/.config/dashboard/tasks.json), shared with the dashboard app and
// its `dashboard` CLI. Tasks are recurrence rules (daily, weekly by weekday, or one date), so the
// same rules decide which tasks fall on a given day as in the dashboard's own calendar. Edits go
// through integration/dashboard-tasks, which re-reads the live file; this service never writes it.
// Check-offs are Island's own: tasks.json has no per-occurrence state to put them in.
Singleton {
    id: root

    readonly property string tasksPath: Quickshell.env("ISLAND_DASHBOARD_TASKS_FILE") || Quickshell.env("HOME") + "/.config/dashboard/tasks.json"
    readonly property string helperPath: Qt.resolvedUrl("../integration/dashboard-tasks").toString().replace(/^file:\/\//, "")
    readonly property var weekdayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    readonly property int doneKeepDays: 120

    // Parsed rules: { id, task, type, value, createdAt, days }.
    property var rules: []
    property bool ready: false
    // Why the list can't be read (editing is disabled), and why the last edit failed.
    property string error: ""
    property string actionError: ""
    // Per date key ("yyyy-MM-dd"): ids of the occurrences checked off in Island.
    property var done: ({})
    property bool busy: operations.length > 0 || writer.running
    property var operations: []

    function pad2(n) { return (n < 10 ? "0" : "") + n }
    function dateKey(date) { return date.getFullYear() + "-" + pad2(date.getMonth() + 1) + "-" + pad2(date.getDate()) }

    function matches(rule, key) {
        if (rule.type === "daily") return true
        if (rule.type === "date") return rule.value === key
        if (rule.type === "weekly") {
            const parts = key.split("-")
            const date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]))
            return rule.days.includes(weekdayNames[date.getDay()])
        }
        return false
    }

    // Tasks that fall on the date, in file order, each with its check-off state.
    function tasksFor(key) {
        const checked = done[key] || []
        return rules.filter(rule => matches(rule, key)).map(rule => ({
            id: rule.id, task: rule.task, type: rule.type, value: rule.value,
            createdAt: rule.createdAt, done: checked.includes(rule.id)
        }))
    }

    function countFor(key) { return rules.reduce((total, rule) => total + (matches(rule, key) ? 1 : 0), 0) }
    // One-off tasks due on the date. Daily and weekly rules would put a mark on most days, so the
    // grid marks only these.
    function dueCountFor(key) { return rules.reduce((total, rule) => total + (rule.type === "date" && rule.value === key ? 1 : 0), 0) }

    function openCountFor(key) {
        const checked = done[key] || []
        return rules.reduce((total, rule) => total + (matches(rule, key) && !checked.includes(rule.id) ? 1 : 0), 0)
    }

    function parse(text) {
        const data = JSON.parse(text)
        if (!Array.isArray(data)) throw new Error("tasks.json is not a list")
        const parsed = []
        for (const item of data) {
            if (!item || typeof item !== "object") continue
            const task = String(item.task ?? "").trim()
            if (!task) continue
            const type = String(item.recurrence_type ?? "")
            const value = String(item.recurrence_value ?? "")
            const createdAt = String(item.created_at ?? "")
            parsed.push({
                id: createdAt + "|" + task, task, type, value, createdAt,
                days: type === "weekly" ? value.split(",").map(day => day.trim()).filter(day => day) : []
            })
        }
        return parsed
    }

    function add(text, type, value) {
        const task = String(text).replace(/[\r\n]+/g, " ").trim()
        if (!task || !ready || error) return false
        enqueue(["add", task, type, value])
        return true
    }

    function remove(rule) {
        if (!rule || !ready || error) return false
        enqueue(["remove", rule.task, rule.createdAt])
        return true
    }

    function setDone(key, id, value) {
        const next = Object.assign({}, done)
        const list = (next[key] || []).filter(entry => entry !== id)
        if (value) list.push(id)
        if (list.length) next[key] = list
        else delete next[key]
        done = next
        saveDone()
    }

    function enqueue(args) {
        actionError = ""
        operations = operations.concat([args])
        runNext()
    }

    function runNext() {
        if (writer.running || operations.length === 0) return
        const [next, ...rest] = operations
        operations = rest
        writer.command = [root.helperPath, ...next]
        writer.running = true
    }

    function saveDone() {
        // Only the recent past matters; old check-offs would grow the file forever.
        const cutoff = new Date()
        cutoff.setDate(cutoff.getDate() - doneKeepDays)
        const oldest = dateKey(cutoff)
        const pruned = {}
        for (const key of Object.keys(done)) if (key >= oldest) pruned[key] = done[key]
        doneStore.setText(JSON.stringify(pruned) + "\n")
    }

    FileView {
        id: store

        path: root.tasksPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.rules = root.parse(text())
                root.error = ""
            } catch (error) {
                root.error = "Can't read the Dashboard tasks: " + error.message
            }
            root.ready = true
        }
        onLoadFailed: error => {
            // A missing file is just an empty list; `dashboard` creates it on the first add.
            if (error === FileViewError.FileNotFound) {
                root.rules = []
                root.error = ""
            } else {
                root.error = "Can't open the Dashboard tasks"
            }
            root.ready = true
        }
    }

    FileView {
        id: doneStore

        path: ThemeService.stateDirectory + "/calendar-tasks.json"
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(text())
                root.done = data && typeof data === "object" && !Array.isArray(data) ? data : ({})
            } catch (error) {
                root.done = ({})
            }
        }
    }

    // `mv` replaces the file, which can end the file watch; this keeps the list live regardless.
    Timer {
        interval: 4000
        running: root.ready
        repeat: true
        onTriggered: store.reload()
    }

    Process {
        id: writer

        stderr: StdioCollector {}
        onExited: code => {
            if (code !== 0) root.actionError = stderr.text.trim() || "Couldn't update the Dashboard tasks"
            store.reload()
            root.runNext()
        }
    }
}
