pragma Singleton

import Quickshell
import Quickshell.Io
import Shell.Integration

Singleton {
    id: root

    readonly property string styleFile: Quickshell.env("SHELL_NOTIFICATION_STYLE") || System.configHome + "/themes/current/ward.css"
    property var styleVariables: ({})
    readonly property var variables: {
        const result = Object.assign({}, styleVariables);
        for (const [name, value] of Object.entries(Colors.values))
            if (!("--" + name in result))
                result["--" + name] = value;
        return result;
    }

    function format(text: string): var {
        return NotificationMarkup.format(text, variables);
    }

    function reload(): void { style.reload(); }

    FileView {
        id: style
        path: root.styleFile
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const variables = {};
            const expression = /(--[\w-]+)\s*:\s*([^;{}]+);/g;
            let match;
            const css = text().replace(/\/\*[\s\S]*?\*\//g, "");
            while ((match = expression.exec(css)) !== null)
                variables[match[1]] = match[2].trim();
            root.styleVariables = variables;
        }
    }
}
