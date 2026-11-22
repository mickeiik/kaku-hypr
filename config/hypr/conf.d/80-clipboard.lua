-- Clipboard (wl-clipboard, cliphist: Fedora packages)
--   Super+C       copy, in any app: sends Ctrl+Insert, the copy key every app knows,
--                 even terminals, where Ctrl+C stops the program
--   Super+V       paste, in any app: sends Shift+Insert
--   Ctrl+Super+V  clipboard history (the launcher's Clipboard history menu; picking
--                 an entry copies it back, then paste as usual)
-- foot is set up to use Ctrl+Insert / Shift+Insert for the clipboard (foot.ini).
hl.on("hyprland.start", function()
    hl.exec_cmd("wl-paste --watch cliphist store")
end)
hl.bind("SUPER + C", hl.dsp.send_shortcut({ mods = "CTRL", key = "Insert" }), { description = "Copy (any app)" })
hl.bind("SUPER + V", hl.dsp.send_shortcut({ mods = "SHIFT", key = "Insert" }), { description = "Paste (any app)" })
hl.bind("SUPER + CTRL + V", hl.dsp.exec_cmd("qs ipc call launcher menu clipboard"), { description = "Clipboard history" })
