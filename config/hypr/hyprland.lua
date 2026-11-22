-- Hyprland config (Tokyo Night, square corners). Hyprland 0.57+: Lua (hl.* API,
-- https://wiki.hypr.land/configuring/). The rest is in conf.d/*.lua, read in name
-- order after this file. Machine-specific files there (20-monitors.lua, written by
-- the Display panel) aren't part of kaku-hypr.
-- Every shortcut has a description: that's what the launcher's Keyboard shortcuts
-- list shows (ShortcutsService.qml reads them from `hyprctl binds -j`).

local mod = "SUPER"
local term = "foot"
local menu = "qs ipc call launcher toggle"

local function bind(keys, description, dispatcher, opts)
    opts = opts or {}
    opts.description = description
    return hl.bind(keys, dispatcher, opts)
end
local function run(cmd)
    return hl.dsp.exec_cmd(cmd)
end

---- Screens: each one at its best mode, side by side. The Display panel saves what's
---- set there in conf.d/20-monitors.lua, one rule per screen, which replaces this one.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

---- Look
hl.config({
    general = {
        border_size = 2,
        gaps_in = 0,
        gaps_out = 0,
        col = {
            active_border = "rgb(7aa2f7)",
            inactive_border = "rgb(414868)",
        },
        layout = "dwindle",
        resize_on_border = true,
    },
    decoration = {
        rounding = 0,
        blur = { enabled = false },
        shadow = { enabled = false },
    },
    animations = { enabled = true },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        background_color = "rgb(1a1b26)", -- behind the wallpaper (Wallpaper.qml)
        focus_on_activate = true,
    },
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
    -- Each new window splits the focused one along its longer side (what autotiling did on Sway)
    dwindle = { preserve_split = true },
})

hl.curve("out", { type = "bezier", points = { { 0.2, 1 }, { 0.3, 1 } } })
hl.animation({ leaf = "global", enabled = true, speed = 2, bezier = "out" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "out", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2, bezier = "out", style = "slidevert" })

---- Apps
bind(mod .. " + Return", "Terminal", run(term))
bind(mod .. " + space", "App launcher", run(menu))
bind(mod .. " + SHIFT + B", "Web browser", run("qs ipc call browser open"))
bind(mod .. " + ALT + B", "Private browser window", run("qs ipc call browser openPrivate"))
bind(mod .. " + W", "Close window", hl.dsp.window.close())
bind(mod .. " + SHIFT + Q", "Close window", hl.dsp.window.close())

---- Mouse: Super + left drag = move, Super + right drag = resize
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

---- Session
bind(mod .. " + SHIFT + C", "Reload Hyprland config", hl.dsp.reload_config())
bind(mod .. " + SHIFT + E", "Power menu (log out, restart...)", run("qs ipc call launcher menu system"))

---- Focus / move
local directions = { H = "left", J = "down", K = "up", L = "right",
                     Left = "left", Down = "down", Up = "up", Right = "right" }
for key, dir in pairs(directions) do
    bind(mod .. " + " .. key, "Focus window " .. dir, hl.dsp.focus({ direction = dir }))
    bind(mod .. " + SHIFT + " .. key, "Move window " .. dir, hl.dsp.window.move({ direction = dir }))
end

---- Workspaces
-- Key codes = physical number row, so this works on AZERTY and QWERTY (10 = key 1 ... 19 = key 0)
for i = 1, 10 do
    local key = "code:" .. (9 + i)
    bind(mod .. " + " .. key, "Go to workspace 1–10", hl.dsp.focus({ workspace = tostring(i) }))
    bind(mod .. " + SHIFT + " .. key, "Move window to workspace 1–10",
        hl.dsp.window.move({ workspace = tostring(i), follow = false }))
end

---- Layout
bind(mod .. " + F", "Fullscreen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
-- Super+V is paste (conf.d/80-clipboard.lua)
bind(mod .. " + E", "Toggle split direction", hl.dsp.layout("togglesplit"))
bind(mod .. " + SHIFT + space", "Float / tile window", hl.dsp.window.float({ action = "toggle" }))
-- Scratchpad. Not Super+minus: on AZERTY that's the same key as Super+6 (workspace 6)
bind(mod .. " + SHIFT + S", "Move to scratchpad", hl.dsp.window.move({ workspace = "special:scratch", follow = false }))
bind(mod .. " + S", "Show scratchpad", hl.dsp.workspace.toggle_special("scratch"))

---- Keyboard resize
bind(mod .. " + R", "Resize mode (arrows, Enter to finish)", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    local steps = { H = { -10, 0 }, J = { 0, 10 }, K = { 0, -10 }, L = { 10, 0 },
                    Left = { -10, 0 }, Down = { 0, 10 }, Up = { 0, -10 }, Right = { 10, 0 } }
    for key, d in pairs(steps) do
        hl.bind(key, hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }), { repeating = true })
    end
    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
end)

---- conf.d/*.lua, in name order
local dir = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$") .. "/conf.d"
local files = {}
local list = io.popen('ls "' .. dir .. '"/*.lua 2>/dev/null')
if list then
    for f in list:lines() do files[#files + 1] = f end
    list:close()
end
table.sort(files)
for _, f in ipairs(files) do dofile(f) end
