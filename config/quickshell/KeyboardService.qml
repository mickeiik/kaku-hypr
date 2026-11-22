pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Active keyboard layout (from Hyprland), and switching to the next one. Announces
// switches (Alt+Shift) for the on-screen indicator.
Singleton {
    id: root

    property string name: "" // e.g. "French", "English (US)"

    signal switched()

    // Hyprland sends one event per keyboard device: only a real change counts, and not
    // the first read at startup
    function update(layout) {
        if (layout === name)
            return;
        const first = name === "";
        name = layout;
        if (!first)
            switched();
    }

    function next() {
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"]);
    }

    Process {
        running: true
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                let keyboards = [];
                try {
                    keyboards = JSON.parse(text).keyboards ?? [];
                } catch (e) {
                    return; // Hyprland not answering
                }
                const kb = keyboards.find(k => k.main) ?? keyboards[0];
                if (kb?.active_keymap)
                    root.update(kb.active_keymap);
            }
        }
    }

    // activelayout>>KEYBOARDNAME,LAYOUTNAME (the keyboard's name has no comma)
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activelayout")
                return;
            const data = event.data;
            const layout = data.slice(data.indexOf(",") + 1);
            if (layout && layout !== "error")
                root.update(layout);
        }
    }
}
