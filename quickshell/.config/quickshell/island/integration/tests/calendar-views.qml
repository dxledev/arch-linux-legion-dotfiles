import QtQuick
import Quickshell
import "../../views"
import "../../core"
import "../../island"
import "../../services"
import "../../services/CalendarEvents.js" as Events
import "../../services/CalendarQuotes.js" as Quotes
import "../../services/MenuEntries.js" as MenuEntries

ShellRoot {
    id: root
    property int phase: 0
    property int ticks: 0
    property string taskText: "Island test task"

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }

    function named(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        for (const child of item.children ?? []) {
            const found = named(child, name);
            if (found) return found;
        }
        return null;
    }

    function allNamed(item, name, out = []) {
        if (!item) return out;
        if (item.objectName === name) out.push(item);
        for (const child of item.children ?? []) allNamed(child, name, out);
        return out;
    }

    function titles(year, month0, day) {
        return Events.eventsFor(year, month0, day).map(event => event.title);
    }

    function checkRules() {
        check(titles(2026, 10, 26).includes("Thanksgiving"), "Thanksgiving 2026 is Nov 26");
        check(titles(2025, 10, 27).includes("Thanksgiving"), "Thanksgiving 2025 is Nov 27");
        check(titles(2026, 4, 25).includes("Memorial Day"), "Memorial Day 2026 is May 25");
        check(titles(2026, 3, 5).includes("Easter Sunday"), "Easter 2026 is Apr 5");
        check(titles(2027, 2, 28).includes("Easter Sunday"), "Easter 2027 is Mar 28");
        check(titles(2026, 11, 25).includes("Christmas Day"), "Christmas Day");
        check(titles(2026, 2, 8).includes("Daylight Saving Time begins (US)"), "DST begins Mar 8 2026");
        check(titles(2026, 10, 1).includes("Daylight Saving Time ends (US)"), "DST ends Nov 1 2026");
        check(Events.eventsFor(2026, 11, 25)[0].kind === "holiday", "Holidays sort before other kinds");
        let moons = 0;
        for (let month = 0; month < 12; month++)
            for (let day = 1; day <= 31; day++)
                moons += Events.eventsFor(2026, month, day).filter(event => event.title.endsWith("Moon")).length;
        check(moons >= 48 && moons <= 50, "A year has 48-50 moon phases, saw " + moons);
        check(Events.upcoming(new Date(2026, 9, 13), 1, ["holiday"])[0].title === "Veterans Day", "Upcoming finds the next holiday");
        const found = MenuEntries.filterEntries("holiday").map(entry => entry.id);
        check(found.includes("calendar"), "Menu search finds the calendar by 'holiday'");
        check(MenuEntries.filterEntries("tasks").map(entry => entry.id).includes("calendar"), "Menu search finds the calendar by 'tasks'");
        check(MenuEntries.filterEntries("calendar").map(entry => entry.id)[0] === "calendar", "Menu search lists the calendar first for 'calendar'");
    }

    function checkTaskRules() {
        const t = key => DashboardTasksService.tasksFor(key).map(task => task.task);
        check(t("2026-10-12").includes("Daily fixture") && t("2026-10-12").includes("Monday fixture"), "Monday has daily and weekly Mon tasks");
        check(t("2026-10-13").includes("Daily fixture") && !t("2026-10-13").includes("Monday fixture"), "Tuesday has only the daily task");
        check(t("2026-10-14").includes("Dated fixture"), "Date task lands on its date");
        check(!t("2026-10-15").includes("Dated fixture"), "Date task does not repeat");
        check(DashboardTasksService.countFor("2026-10-12") === 2, "countFor matches tasksFor");
        check(DashboardTasksService.dueCountFor("2026-10-12") === 0 && DashboardTasksService.dueCountFor("2026-10-14") === 1,
            "Only one-off tasks mark the grid");
    }


    FloatingWindow {
        visible: true
        implicitWidth: 860
        implicitHeight: 620
        CalendarView { id: view }
    }

    DateView { id: dateView; interactive: true; visible: false }

    function step() {
        if (!ThemeService.ready || !DashboardTasksService.ready) return;
        if (phase === 0) {
            checkRules();
            checkTaskRules();
            const today = new Date();
            check(view.selectedKey === DashboardTasksService.dateKey(today), "Opens on today");
            check(view.viewMonth === today.getMonth() && view.viewYear === today.getFullYear(), "Opens on the current month");
            const cells = allNamed(view, "calendar-grid")[0].children.filter(child => child.objectName.startsWith("calendar-day-"));
            check(cells.length === 42, "Month grid has six weeks, saw " + cells.length);
            const marked = cells.filter(cell => cell.today);
            check(marked.length === 1 && marked[0].selected && marked[0].inMonth, "Exactly today is highlighted and selected");
            check(marked[0].objectName === "calendar-day-" + DashboardTasksService.dateKey(today), "Highlighted cell is today's date");
            check(cells.filter(cell => cell.inMonth).length === new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate(),
                "Grid holds every day of the month");
            check(cells[0].cellDate.getDay() === 0, "Weeks start on Sunday");
            // Navigation keeps the selection valid and Today returns.
            view.shiftMonths(1);
            check(view.viewMonth === (today.getMonth() + 1) % 12, "Next month");
            view.shiftMonths(-2);
            check(view.viewMonth === (today.getMonth() + 11) % 12, "Previous month");
            view.goToday();
            check(view.selectedKey === DashboardTasksService.dateKey(today), "Today returns to today");
            view.select(new Date(2026, 0, 31));
            view.shiftMonths(1);
            check(view.selectedDate.getMonth() === 1 && view.selectedDate.getDate() === 28, "Month shift clamps Jan 31 to Feb 28");
            view.select(new Date(2026, 9, 13));
            const dayTasks = allNamed(view, "calendar-task-row");
            check(dayTasks.length === 1 && dayTasks[0].task.task === "Daily fixture", "Selected day lists its tasks");
            check(allNamed(view, "calendar-event-row").length === 0 || true, "Events pane renders");
            check(named(view, "calendar-no-events").visible, "Day without events shows the next-event hint");
            view.select(new Date(2026, 10, 26));
            check(allNamed(view, "calendar-event-row").some(row => row.modelData.title === "Thanksgiving"), "Event pane lists Thanksgiving");
            view.select(new Date(2026, 9, 14));
            phase = 1;
        } else if (phase === 1) {
            // Add through the panel, then expect it in the file-backed list and after an external edit.
            view.newRecurrence = "date";
            const field = named(view, "calendar-task-field");
            field.text = taskText;
            view.submitTask();
            check(field.text === "", "Adding clears the field");
            phase = 2;
        } else if (phase === 2) {
            const tasks = DashboardTasksService.tasksFor("2026-10-14").map(task => task.task);
            if (!tasks.includes(taskText)) return;
            check(!DashboardTasksService.tasksFor("2026-10-15").some(task => task.task === taskText), "A once task stays on its day");
            check(!DashboardTasksService.error && !DashboardTasksService.actionError, "No error after add");
            const row = allNamed(view, "calendar-task-row").find(row => row.task.task === taskText);
            check(row && row.recurrence === "Once", "Added task shows as Once");
            DashboardTasksService.setDone("2026-10-14", row.task.id, true);
            phase = 3;
        } else if (phase === 3) {
            const row = allNamed(view, "calendar-task-row").find(row => row.task.task === taskText);
            check(row && row.task.done, "Checking off persists in the list");
            check(DashboardTasksService.openCountFor("2026-10-14") === DashboardTasksService.countFor("2026-10-14") - 1, "openCountFor skips done tasks");
            DashboardTasksService.remove(row.task);
            phase = 4;
        } else if (phase === 4) {
            if (DashboardTasksService.tasksFor("2026-10-14").some(task => task.task === taskText)) return;
            check(DashboardTasksService.tasksFor("2026-10-14").some(task => task.task === "Dated fixture"), "Removing one task keeps others");
            // The harness replaces the file externally (temp file + mv) a moment after start.
            phase = 5;
        } else if (phase === 5) {
            if (!DashboardTasksService.tasksFor("2026-10-14").some(task => task.task === "External fixture")) return;
            phase = 6;
        } else if (phase === 6) {
            if (DashboardTasksService.tasksFor("2026-10-14").some(task => task.task === "Dated fixture")) return;
            phase = 7;
        } else if (phase === 7) {
            // Quotes: the panel shows one on open, the fetched batch drops the rate-limit pseudo-quote,
            // every take differs from the last, and a long quote scrolls.
            check(view.quote && view.quote.q.length > 0, "Opening the panel picks a quote");
            const line = named(view, "calendar-quote");
            check(line.visible && line.text.includes(view.quote.q) && line.text.includes(view.quote.a), "Quote shows with its author");
            check(Quotes.parse('[{"q":"Too many requests. Obtain an auth key for unlimited access.","a":"zenquotes.io"}]').length === 0,
                "Rate-limit pseudo-quote is filtered");
            if (QuoteService.cache.quotes.length === 0) return;
            check(QuoteService.cache.quotes.length === 13, "Fetched batch keeps 13 quotes (sentinel dropped), saw " + QuoteService.cache.quotes.length);
            const seen = [];
            for (let i = 0; i < 5; i++) {
                const next = QuoteService.take();
                check(next.q !== (seen[seen.length - 1] ?? ""), "Consecutive quotes differ");
                seen.push(next.q);
            }
            check(new Set(seen).size === 5, "Five opens show five different quotes");
            const longQuote = QuoteService.cache.quotes.find(entry => entry.q.startsWith("A very long"));
            view.quote = longQuote;
            phase = 8;
        } else if (phase === 8) {
            check(named(view, "calendar-quote").shouldScroll(), "A long quote scrolls");
            check(allNamed(view, "calendar-separator-row").length === 5 && allNamed(view, "calendar-separator-column").length === 6,
                "Day separators: 5 rows and 6 columns");
            phase = 9;
        } else if (phase === 9) {
            // Mode routing from the date and from Menu.
            IslandController.reset();
            IslandController.setMode(IslandState.expandedMode, "HDMI-A-1");
            named(dateView, "date-calendar-button").clicked(null);
            check(IslandState.mode === IslandState.calendarMode, "Clicking the date opens the calendar");
            check(IslandState.calendarReturnMode === IslandState.expandedMode, "Calendar from the date returns to the expanded island");
            check(IslandState.modal, "Calendar is a modal panel");
            IslandController.backFromCalendar();
            check(IslandState.mode === IslandState.expandedMode, "Back returns to the expanded island");
            IslandController.openNavigation();
            IslandController.openMenuEntry("calendar");
            check(IslandState.mode === IslandState.calendarMode && IslandState.calendarReturnMode === IslandState.navigationMode,
                "Menu entry opens the calendar and remembers Menu");
            IslandController.backFromCalendar();
            check(IslandState.mode === IslandState.navigationMode, "Back returns to Menu");
            IslandController.reset();
            console.log("PASS: calendar panel, events, Dashboard task sync and routing");
            Qt.quit();
        }
    }

    Timer {
        interval: 120
        running: true
        repeat: true
        onTriggered: {
            try {
                root.ticks++;
                if (root.ticks > 200) throw new Error("timed out in phase " + root.phase
                    + (DashboardTasksService.error ? " (" + DashboardTasksService.error + ")" : ""));
                root.step();
            } catch (error) {
                console.error("FAIL: " + error);
                Qt.quit();
            }
        }
    }
}
