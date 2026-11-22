-- The bar, panels, launcher, notifications and lock screen: Quickshell (~/.config/quickshell).
-- Started again a second later if it crashes (killed by a signal) while Hyprland is
-- still running. Not after a normal exit (`qs kill`, or another instance already
-- running: -n).
hl.on("hyprland.start", function()
    hl.exec_cmd("sh -c 'while :; do qs -n; [ $? -ge 128 ] && hyprctl -j version >/dev/null 2>&1 || break; sleep 1; done'")
end)
