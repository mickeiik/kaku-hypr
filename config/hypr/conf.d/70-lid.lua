-- Closing the lid locks, even when docked (logind only suspends when undocked;
-- then the before-sleep hook locks too, which is harmless)
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("~/.local/bin/lock-screen"), { locked = true })
