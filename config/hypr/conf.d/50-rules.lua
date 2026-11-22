-- Terminals opened by the launcher (package browsers, updates): floating, centered
hl.window_rule({
    name = "launcher-term",
    match = { class = "^launcher-term$" },
    float = true,
    size = { 1100, 820 },
    center = true,
})
-- Small windows that are better floating (what Fedora's Sway rules did)
hl.window_rule({
    name = "float-small",
    match = { class = "^(org.pulseaudio.pavucontrol|pavucontrol|pavucontrol-qt)$" },
    float = true,
    center = true,
})
hl.window_rule({
    name = "firefox-sharing-indicator",
    match = { class = "^firefox$", title = "^Firefox — Sharing Indicator$" },
    float = true,
})
-- No idle lock while a browser plays fullscreen (videos)
hl.window_rule({
    name = "browser-fullscreen-no-idle",
    match = { class = "^(firefox|brave-browser|com.brave.Browser|chromium-browser|Chromium-browser)$" },
    idle_inhibit = "fullscreen",
})
