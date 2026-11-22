pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// The screens as Hyprland sees them, turned-off ones included (hyprctl monitors all):
// on/off, scale, HDR and the main screen, set from the display panel. They're also
// written to ~/.config/hypr/conf.d/20-monitors.lua (not synced: it's per machine),
// so they survive a restart: one hl.monitor({...}) line per screen, rebuilt from what the
// screen has now (mode, position, scale, rotation, HDR), so a layout written by hand
// in that file is kept. A turned-off screen's last rule is kept in a "-- on: " comment,
// to turn it back on the way it was.
// One screen always stays on: the last one can't be turned off, and if none is on for
// a few seconds (the screen left on was unplugged, or a DisplayPort screen dropped out
// while asleep) the others are turned on for now, not saved, and back off once a
// screen that was on returns. shell.qml creates this from the start for that.
//
// The main screen is where workspace 1 is and what has focus at login (the launcher,
// notifications and indicators follow the focused screen).
//
// HDR is offered for screens whose EDID says they take HDR10 (bitdepth = 10,
// cm = "hdr"). When Hyprland doesn't turn it on, hdrRefused names that screen, for the
// panel to say so.
Singleton {
    id: root

    // One object per screen: name, active, model, current_mode { width, height,
    // refresh (mHz) }, scale, hdr, and hypr (hyprctl's own object)
    property var outputs: []
    readonly property int activeCount: outputs.filter(o => o.active).length
    property var hdrCapable: [] // screen names
    property string hdrRefused: ""
    property string hdrAsked: "" // screen whose HDR was just turned on, checked by hdrCheck
    property string primary: "" // the main screen ("": none chosen)

    property var fallbackOn: [] // screens turned on only because none was on

    readonly property string file: "~/.config/hypr/conf.d/20-monitors.lua"

    function setEnabled(name, on) {
        if (!on && activeCount <= 1)
            return;
        fallbackOn = fallbackOn.filter(n => n !== name); // the user's choice wins
        on ? enable(name) : disable(name);
    }
    function setScale(name, scale) {
        apply(name, { scale: scale });
    }
    function setHdr(name, on) {
        hdrRefused = "";
        hdrAsked = on ? name : "";
        apply(name, { hdr: on });
        if (on)
            hdrCheck.restart();
    }
    // Workspace 1 moves there now (and is shown); at login it's put there and focused
    function setPrimary(name) {
        primary = name;
        Quickshell.execDetached(["sh", "-c", `
            hyprctl -q eval "hl.workspace_rule({ workspace = \\"1\\", monitor = \\"$1\\", default = true })"
            hyprctl -q dispatch "hl.dsp.workspace.move({ workspace = \\"1\\", monitor = \\"$1\\" })"
            hyprctl -q dispatch 'hl.dsp.focus({ workspace = "1" })'
            f=${file}
            touch "$f"
            sed -i '/^hl.workspace_rule({ workspace = "1",/d; /^hl.on("hyprland.start", function() hl.dispatch(hl.dsp.focus({ monitor = /d' "$f"
            printf '%s\\n' "hl.workspace_rule({ workspace = \\"1\\", monitor = \\"$1\\", default = true })" \\
                "hl.on(\\"hyprland.start\\", function() hl.dispatch(hl.dsp.focus({ monitor = \\"$1\\" })) end)" >> "$f"
        `, "main-screen", name]);
        rereadAfter.restart();
    }

    // The monitor rule (a Lua table for hl.monitor) of a screen that's on, with
    // changes ({ scale, hdr }).
    // In HDR, the desktop and other SDR content would look washed out with Hyprland's
    // defaults (sRGB curve, black at 0.2 nits, white at 80): gamma 2.2, a deep black
    // and a 250-nit white instead. Black and white levels set by hand in the file are kept.
    function ruleFor(o, change) {
        const h = o.hypr;
        const scale = change.scale ?? o.scale;
        const hdr = change.hdr ?? o.hdr;
        const sdrMin = o.hdr && h.sdrMinLuminance !== undefined && h.sdrMinLuminance !== 0.2 ? h.sdrMinLuminance : 0.005;
        const sdrMax = o.hdr && h.sdrMaxLuminance !== undefined && h.sdrMaxLuminance !== 80 ? h.sdrMaxLuminance : 250;
        return `{ output = "${o.name}", mode = "${h.width}x${h.height}@${h.refreshRate.toFixed(3)}", `
            + `position = "${h.x}x${h.y}", scale = ${scale}, transform = ${h.transform}`
            + (hdr ? `, bitdepth = 10, cm = "hdr", sdr_eotf = "gamma22", sdr_min_luminance = ${sdrMin}, sdr_max_luminance = ${sdrMax} }` : " }");
    }

    // Applies a rule now, and saves it unless persist is false: the screen's
    // hl.monitor line is replaced. The "-- on: " comment keeps the rule of a turned-off
    // screen (written by disable(), read by enable()).
    function run(name, rule, persist, keep) {
        Quickshell.execDetached(["sh", "-c", `
            hyprctl -q eval "hl.monitor($2)"
            [ "$3" = 1 ] || exit 0
            f=${file}
            touch "$f"
            sed -i "/^hl.monitor({ output = \\"$1\\",/d; /^-- on: { output = \\"$1\\",/d" "$f"
            [ -z "$4" ] || echo "-- on: $4" >> "$f"
            echo "hl.monitor($2)" >> "$f"
        `, "display", name, rule, persist ? "1" : "0", keep ?? ""]);
        rereadAfter.restart();
    }
    function apply(name, change) {
        const o = outputs.find(o => o.name === name);
        if (o?.active)
            run(name, ruleFor(o, change), true);
    }
    function disable(name, persist = true) {
        const o = outputs.find(o => o.name === name);
        if (o?.active)
            run(name, `{ output = "${name}", disabled = true }`, persist, persist ? ruleFor(o, {}) : "");
    }
    // Back the way it was ("-- on: " rule), or Hyprland's choice of mode and place
    function enable(name, persist = true) {
        Quickshell.execDetached(["sh", "-c", `
            f=${file}
            rule=$(sed -n "s/^-- on: \\({ output = \\"$1\\",.*\\)/\\1/p" "$f" 2>/dev/null | tail -n 1)
            [ -n "$rule" ] || rule="{ output = \\"$1\\", mode = \\"preferred\\", position = \\"auto\\", scale = 1 }"
            hyprctl -q eval "hl.monitor($rule)"
            [ "$2" = 1 ] || exit 0
            touch "$f"
            sed -i "/^hl.monitor({ output = \\"$1\\",/d; /^-- on: { output = \\"$1\\",/d" "$f"
            echo "hl.monitor($rule)" >> "$f"
        `, "display", name, persist ? "1" : "0"]);
        rereadAfter.restart();
    }

    // hyprctl's monitor object, in the shape the panel uses
    function fromHypr(h) {
        return {
            name: h.name,
            active: !h.disabled,
            model: h.model || h.description,
            current_mode: { width: h.width, height: h.height, refresh: Math.round(h.refreshRate * 1000) },
            scale: h.scale,
            hdr: h.colorManagementPreset === "hdr" || h.colorManagementPreset === "hdredid",
            hypr: h
        };
    }

    function refresh() {
        if (!reader.running)
            reader.running = true;
        else
            rereadAfter.restart();
    }

    // Plugged, unplugged, turned on or off
    Connections {
        target: Quickshell
        function onScreensChanged() {
            root.refresh();
            hdrReader.running = true;
        }
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (/^monitor(added|removed)|^configreloaded$/.test(event.name))
                root.refresh();
        }
    }

    // hyprctl runs in the background: re-read once it's applied
    Timer {
        id: rereadAfter
        interval: 300
        onTriggered: root.refresh()
    }

    // No screen on: wait a moment (a DisplayPort screen waking up comes back by itself),
    // then turn the others on, for now only
    Timer {
        id: noneOn
        interval: 3000
        onTriggered: {
            const list = root.outputs;
            if (list.length === 0 || list.some(o => o.active))
                return;
            root.fallbackOn = list.map(o => o.name);
            for (const o of list)
                root.enable(o.name, false);
        }
    }

    // Turning HDR on changes the screen's mode: give it time, then see whether it took
    Timer {
        id: hdrCheck
        interval: 1500
        onTriggered: {
            const o = root.outputs.find(o => o.name === root.hdrAsked);
            if (o && !o.hdr)
                root.hdrRefused = root.hdrAsked;
            root.hdrAsked = "";
        }
    }

    Process {
        id: reader
        running: true
        command: ["hyprctl", "-j", "monitors", "all"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list;
                try {
                    list = JSON.parse(text).map(h => root.fromHypr(h));
                } catch (e) {
                    return;
                }
                root.outputs = list;
                if (list.length > 0 && !list.some(o => o.active)) {
                    if (!noneOn.running)
                        noneOn.start();
                } else {
                    noneOn.stop();
                    // A screen that was on is back: turn the stand-ins off again
                    const back = list.some(o => o.active && !root.fallbackOn.includes(o.name));
                    if (back && root.fallbackOn.length > 0) {
                        for (const n of root.fallbackOn) {
                            if (list.some(o => o.name === n && o.active))
                                root.disable(n, false);
                        }
                        root.fallbackOn = [];
                    }
                }
                Hyprland.refreshMonitors();
            }
        }
    }

    // The saved main screen
    Process {
        running: true
        command: ["sh", "-c", `sed -n 's/^hl.workspace_rule({ workspace = "1", monitor = "\\([^"]*\\)".*/\\1/p' ~/.config/hypr/conf.d/20-monitors.lua 2>/dev/null`]
        stdout: StdioCollector {
            onStreamFinished: root.primary = text.trim()
        }
    }

    // Screens that take HDR10: the HDR static metadata block of their EDID (CTA-861
    // extended tag 6) lists the PQ transfer function (bit 2)
    Process {
        id: hdrReader
        running: true
        command: ["python3", "-I", "-c", `
import glob, re
for f in glob.glob("/sys/class/drm/card*-*/edid"):
    d = open(f, "rb").read()
    for i in range(1, len(d) // 128):
        b = d[i * 128:(i + 1) * 128]
        if b[0] != 2:
            continue
        p = 4
        while p < b[2]:
            tag, n = b[p] >> 5, b[p] & 31
            if tag == 7 and n >= 2 and b[p + 1] == 6 and b[p + 2] & 4:
                print(re.sub(r"^card[0-9]+-", "", f.split("/")[4]))
            p += 1 + n
`]
        stdout: StdioCollector {
            onStreamFinished: root.hdrCapable = text.split("\n").filter(n => n)
        }
    }
}
