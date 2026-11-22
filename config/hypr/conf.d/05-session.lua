-- At login: Hyprland itself hands its environment to systemd and D-Bus and starts
-- hyprland-session.target (so graphical-session.target: voxtype, the keyring...).
-- Then the XDG autostart entries (~/.config/autostart, /etc/xdg/autostart).
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start xdg-desktop-autostart.target")
    hl.exec_cmd("xdg-user-dirs-update")
end)
