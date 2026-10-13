import QtQuick
import Quickshell.Io

// One helper invocation at a time. Starting a new run kills the previous one and drops its
// output, so only the latest request ever reports back through `finished`.
Process {
    id: root

    property var queued: null
    property var current: null
    property string buffer: ""
    property string errors: ""

    // `line` streams each stdout line as it arrives (used for per-scheme palette previews).
    signal line(var tag, string text)
    signal finished(var tag, int code, string output, string errors)

    function run(argv, tag, env) {
        const request = { argv: argv, tag: tag, env: env || ({}) };
        if (running) {
            queued = request;
            running = false;
            return;
        }
        launch(request);
    }

    function cancel() {
        queued = null;
        current = null;
        if (running) running = false;
    }

    function launch(request) {
        current = request;
        buffer = "";
        errors = "";
        environment = request.env;
        command = request.argv;
        running = true;
    }

    stdout: SplitParser {
        onRead: data => {
            root.buffer += data + "\n";
            if (root.current) root.line(root.current.tag, data);
        }
    }
    stderr: SplitParser {
        onRead: data => root.errors += data + "\n"
    }
    onExited: code => {
        if (queued) {
            const next = queued;
            queued = null;
            launch(next);
            return;
        }
        const done = current;
        current = null;
        if (done) finished(done.tag, code, buffer, errors);
    }
}
