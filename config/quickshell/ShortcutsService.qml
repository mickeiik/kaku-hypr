pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Keyboard shortcuts as Hyprland has them (`hyprctl binds -j`), named by their
// description (~/.config/hypr/hyprland.lua and conf.d/). Binds without one are left
// out, except media keys, named after the key. Read again when the config reloads.
Singleton {
    id: root

    property var list: [] // [{ keys, description }]

    function refresh() {
        if (!reader.running)
            reader.running = true;
    }

    // Media keys get their name from the key itself
    readonly property var keyNames: ({
        XF86AudioRaiseVolume: "Volume up", XF86AudioLowerVolume: "Volume down", XF86AudioMute: "Mute",
        XF86AudioMicMute: "Mute microphone", XF86MonBrightnessUp: "Brightness up", XF86MonBrightnessDown: "Brightness down",
        XF86AudioPlay: "Play / pause", XF86AudioPause: "Pause", XF86AudioNext: "Next track", XF86AudioPrev: "Previous track",
        XF86AudioStop: "Stop"
    })

    // Modifier bits of hyprctl's modmask, in display order
    readonly property var modBits: [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]]

    function prettyKeys(modmask, key) {
        const names = { Return: "Enter", space: "Space", Print: "Print",
                        Left: "←", Right: "→", Up: "↑", Down: "↓", minus: "-" };
        const mods = modBits.filter(([bit]) => modmask & bit).map(([, name]) => name);
        return mods.concat([names[key] ?? (key.length === 1 ? key.toUpperCase() : key)]).join("+");
    }

    function parse(text) {
        let binds;
        try {
            binds = JSON.parse(text);
        } catch (e) {
            return; // Hyprland not answering
        }
        const byDescription = new Map();
        for (const b of binds) {
            if (b.submap !== "" || b.release || b.mouse)
                continue;
            let key = b.key;
            // Workspace shortcuts (key codes of the number row) are summarised in one line each
            if (!key && b.keycode >= 10 && b.keycode <= 19 && /workspace 1–10/.test(b.description))
                key = "1…0";
            if (!key)
                continue; // other raw key codes aren't readable
            const description = b.has_description ? b.description : keyNames[key];
            if (!description)
                continue;
            const pretty = prettyKeys(b.modmask, key);
            const entry = byDescription.get(description);
            if (!entry)
                byDescription.set(description, { description: description, keys: [pretty] });
            else if (!entry.keys.includes(pretty))
                entry.keys.push(pretty);
        }
        list = [...byDescription.values()].map(e => ({ description: e.description, keys: e.keys.join("  ") }));
    }

    Component.onCompleted: refresh()

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded")
                root.refresh();
        }
    }

    Process {
        id: reader
        command: ["hyprctl", "-j", "binds"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }
}
