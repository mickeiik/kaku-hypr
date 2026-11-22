-- The bar's brightness service changes the level (never below 1%) and shows the
-- on-screen indicator (~/.config/quickshell/Osd.qml). Still works while locked.
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs ipc call brightness step -1"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("qs ipc call brightness step 1"), { locked = true })
