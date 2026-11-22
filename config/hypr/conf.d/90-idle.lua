-- Lock and screen off when idle: swayidle (it works on any compositor with
-- ext-idle-notify), its timeouts in ~/.config/swayidle/config
hl.on("hyprland.start", function()
    hl.exec_cmd("swayidle -w")
end)
