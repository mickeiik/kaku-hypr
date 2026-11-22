hl.config({
    input = {
        kb_layout = "fr",
        follow_mouse = 1,
        touchpad = {
            tap_to_click = true,
            natural_scroll = true,
        },
        -- Hold the middle button and move the mouse to scroll, in any app. A quick middle
        -- click (without moving) is still a middle click: paste, open link in a new tab...
        scroll_method = "on_button_down",
        scroll_button = 274,
    },
})
