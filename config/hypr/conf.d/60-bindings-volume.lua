-- The bar's volume service changes the level (5% steps, up to 100%) and shows the
-- on-screen indicator (~/.config/quickshell/Osd.qml). Holding a key is repeated by
-- Quickshell (press starts, release stops). Still works while locked.
local function qs(args, opts)
    opts = opts or {}
    opts.locked = true
    return hl.dsp.exec_cmd("qs ipc call volume " .. args), opts
end
hl.bind("XF86AudioRaiseVolume", qs("hold 1"))
hl.bind("XF86AudioLowerVolume", qs("hold -1"))
hl.bind("XF86AudioRaiseVolume", qs("release 1", { release = true }))
hl.bind("XF86AudioLowerVolume", qs("release -1", { release = true }))
hl.bind("XF86AudioMute", qs("mute"))
hl.bind("XF86AudioMicMute", qs("micMute"))
