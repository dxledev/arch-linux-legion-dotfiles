pragma Singleton

import Quickshell
import Quickshell.Io
import Shell.Integration
import qs.services

Singleton {
    id: root

    readonly property string styleFile: Quickshell.env("SHELL_NOTIFICATION_STYLE") || System.configHome + "/themes/.caelestia-use/ward.css"
    property var styleVariables: ({})
    readonly property var variables: {
        const result = Object.assign({}, styleVariables);
        if (Colours.source === "dynamic") {
            Object.assign(result, dynamicColorVariables());
        } else {
            for (const [name, value] of Object.entries(Colors.values))
                if (!("--" + name in result))
                    result["--" + name] = value;
        }
        return result;
    }

    function dynamicColorVariables(): var {
        const palette = Colours.current;
        const background = palette.m3background;
        const backgroundGray = palette.m3surfaceContainerHighest;
        return {
            "--background": Qt.rgba(background.r, background.g, background.b, 217 / 255),
            "--backgroundAlt": palette.m3surfaceContainerLow,
            "--backgroundAlpha": Qt.rgba(backgroundGray.r, backgroundGray.g, backgroundGray.b, 0.87),
            "--backgroundGray": backgroundGray,
            "--foreground": palette.m3onBackground,
            "--foregroundInactive": palette.m3onSurfaceVariant,
            "--primary": palette.m3primary,
            "--muted": palette.m3onSurfaceVariant,
            "--border": palette.m3outline,
            "--secondary": palette.m3secondary,
            "--success": palette.m3success,
            "--warning": palette.m3tertiary,
            "--danger": palette.m3error,
            "--text-color": palette.m3onBackground,
            "--primary-color": palette.m3primary,
            "--secondary-color": palette.m3secondary,
            "--border-color": palette.m3outline
        };
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
