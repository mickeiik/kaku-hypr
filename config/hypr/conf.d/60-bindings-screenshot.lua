-- Screenshots go to ~/Pictures/Screenshots, are also copied to the clipboard, and
-- show a notification (~/.local/bin/screenshot, also used by the launcher's Capture menu)
hl.bind("Print", hl.dsp.exec_cmd("~/.local/bin/screenshot area"), { description = "Screenshot of an area" })
hl.bind("ALT + Print", hl.dsp.exec_cmd("~/.local/bin/screenshot active"), { description = "Screenshot of the window" })
hl.bind("CTRL + Print", hl.dsp.exec_cmd("~/.local/bin/screenshot output"), { description = "Screenshot of the screen" })
