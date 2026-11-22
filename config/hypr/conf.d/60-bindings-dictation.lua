-- Speech to text (voxtype, settings in ~/.config/voxtype/config.toml): hold Super+D,
-- speak, let go, and the text is typed where the cursor is. Esc while holding cancels.
hl.bind("SUPER + D", hl.dsp.exec_cmd("voxtype record start"), { description = "Dictate (hold, speak, let go)" })
hl.bind("SUPER + D", hl.dsp.exec_cmd("voxtype record stop"), { release = true })

-- While listening (voxtype switches here when it starts): letting go of D or Super
-- stops, whichever comes first. Other keys still reach the app.
local stop = function()
    hl.exec_cmd("voxtype record stop")
    hl.dispatch(hl.dsp.submap("reset"))
end
hl.define_submap("voxtype_recording", function()
    hl.bind("D", stop, { release = true })
    hl.bind("SUPER + D", stop, { release = true })
    hl.bind("SUPER + Super_L", stop, { release = true })
    hl.bind("SUPER + Super_R", stop, { release = true })
    hl.bind("Escape", function()
        hl.exec_cmd("voxtype record cancel")
        hl.dispatch(hl.dsp.submap("reset"))
    end)
end)

-- While voxtype types the text: modifier keys still held would turn the typed letters
-- into shortcuts (Super+h...), so they're ignored. No Escape here: it makes wtype drop
-- the first character. F12 gets out if voxtype ever leaves Hyprland stuck in this submap.
hl.define_submap("voxtype_suppress", function()
    for _, key in ipairs({ "Super_L", "Super_R", "Control_L", "Control_R", "Alt_L", "Alt_R", "Shift_L", "Shift_R" }) do
        hl.bind(key, hl.dsp.no_op())
    end
    hl.bind("F12", hl.dsp.submap("reset"))
end)
