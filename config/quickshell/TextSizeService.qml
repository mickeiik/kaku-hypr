pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// One "text size" for the whole desktop: this shell, GTK apps (Firefox...),
// and foot. GTK's text-scaling-factor is the stored
// value; 13px in the shell = factor 1.0 = "100%".
Singleton {
    id: root

    readonly property int basePx: 13
    readonly property int minPx: 10
    readonly property int maxPx: 20
    property int px: 15

    function set(p) {
        px = Math.max(minPx, Math.min(maxPx, Math.round(p)));
        applyTimer.restart();
    }

    // Read the saved size once at startup
    Process {
        running: true
        command: ["gsettings", "get", "org.gnome.desktop.interface", "text-scaling-factor"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = parseFloat(text);
                if (!isNaN(f))
                    root.px = Math.round(f * root.basePx);
            }
        }
    }

    // Apply to the other apps once the slider settles
    Timer {
        id: applyTimer
        interval: 400
        onTriggered: Quickshell.execDetached(["sh", "-c", `
            gsettings set org.gnome.desktop.interface text-scaling-factor "$1"
            sed -i -E "s/^(font=JetBrains Mono:size=)[0-9.]+/\\\\1$2/" ~/.config/foot/foot.ini
        `, "text-size",
            (root.px / root.basePx).toFixed(3),
            String(Math.round(root.px * 11 / root.basePx))])
    }
}
