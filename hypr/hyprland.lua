-- ~/.config/hypr/hyprland.lua
-- Hyprland Lua config (hyprlang is deprecated since v0.55).
-- Ported from hyprland.conf by hyprconf2lua + manual review against the
-- official example (hyprwm/Hyprland example/hyprland.lua) and the sys stubs
-- (/usr/share/hypr/stubs/hl.meta.lua).

--------------
-- MONITORS --
--------------

hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = 1.5,
})

-- Virtual output used by ~/.local/bin/workspace-stream when it exists.
hl.monitor({
    output   = "YT-STREAM",
    mode     = "1920x1080@60",
    position = "auto-right",
    scale    = 1.5,
})

-- Extended HDMI mode: laptop workspaces 1-5, flat-screen workspaces 6-10.
-- Enable by uncommenting the monitor block and the require below.
-- hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "1280x0", scale = 1.5 })
-- require("workspaces-hdmi-extended")

-- Mirror mode alternative: comment the extended monitor + require above, then uncomment this.
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1920x1080@60",
    position = "auto",
    scale    = 1.5,
    mirror   = "eDP-1",
})

------------------
-- XWAYLAND ----
------------------

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

--------------------------
-- ENVIRONMENT VARIABLES --
--------------------------

hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("HYPRCURSOR_SIZE", 24)
hl.env("NIXOS_OZONE_WL", 1)
hl.env("SHELL", "/usr/bin/bash")

---------------
-- VARIABLES --
---------------

local terminal = "kitty env SHELL=/usr/bin/bash zellij attach -c main"
local mainMod = "SUPER"

--------------
-- GENERAL --
--------------

hl.config({
    general = {
        gaps_in        = 0,
        gaps_out       = 0,
        border_size    = 2,
        resize_on_border = false,
        allow_tearing  = false,
        layout         = "dwindle",
        col = {
            active_border   = "rgba(285577ff)",
            inactive_border = "rgba(333333ff)",
        },
    },
})

-----------------
-- DECORATION --
-----------------

hl.config({
    decoration = {
        rounding         = 0,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },
    },
})

----------------
-- ANIMATIONS --
----------------

hl.config({
    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}   } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}   } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}      } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 0.7,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 0.7,  bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

--------------
-- DWINDLE ---
--------------
hl.config({ dwindle = { preserve_split = true } })

-------------
-- MASTER ---
-------------
hl.config({ master = { new_status = "master" } })

------------
-- MISC ----
------------
hl.config({
    misc = {
        force_default_wallpaper    = -1,
        initial_workspace_tracking = 0,
        disable_hyprland_logo      = true,
        disable_splash_rendering   = true,
        on_focus_under_fullscreen  = 1,
    },
})

-------------
-- INPUT ----
-------------
hl.config({
    input = {
        kb_layout  = "us,ara,de",
        kb_options = "grp:alt_shift_toggle",
        follow_mouse = 1,
        sensitivity = 0,

        touchpad = {
            natural_scroll = true,
        },
    },
})

---------------
-- AUTOSTART --
---------------
hl.on("hyprland.start", function()
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("hyprlauncher --daemon")
    hl.exec_cmd("emacs --daemon")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaybg -o eDP-1 -i ~/Pictures/background.jpg -o HDMI-A-1 -i ~/Pictures/background.jpg")
    hl.exec_cmd("mako")
    hl.exec_cmd("env QT_SCALE_FACTOR=0.6666667 QT_QPA_PLATFORM=wayland flameshot")
    -- Start the XDG Desktop Portal stack (Hyprland backend + router) so
    -- portal-based tools like flameshot capture work.
    hl.exec_cmd("~/.local/bin/start-hyprland-portals")
end)

------------------
-- KEYBINDINGS ---
------------------

hl.bind(mainMod .. " + code:36",                       hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E",                             hl.dsp.exec_cmd("emacsclient -c -a 'emacs'"))
hl.bind(mainMod .. " + Q",                             hl.dsp.window.close())
hl.bind(mainMod .. " + M",                             hl.dsp.exec_cmd("wlogout -b 4 -c 0 -r 0 -m 0 -p layer-shell --no-span"))
hl.bind(mainMod .. " + SHIFT + space",                 hl.dsp.window.float())
hl.bind(mainMod .. " + D",                             hl.dsp.exec_cmd("~/.local/bin/hyprlauncher-toggle"))
hl.bind(mainMod .. " + V",                             hl.dsp.exec_cmd("~/.local/bin/cliphist-picker"))
hl.bind(mainMod .. " + CTRL + M",                      hl.dsp.exec_cmd("~/.local/bin/controller-mouse-toggle"))
hl.bind(mainMod .. " + F",                             hl.dsp.window.fullscreen({ mode = "fullscreen", action = "set" }))
hl.bind(mainMod .. " + SHIFT + F",                     hl.dsp.window.fullscreen())
hl.bind("Print",                                       hl.dsp.exec_cmd("~/.local/bin/flameshot-hyprland"))

-- Isolated YouTube workspace: control the mirrored stream / return to laptop.
hl.bind(mainMod .. " + F11",                           hl.dsp.exec_cmd("~/.local/bin/workspace-stream enter"))
hl.bind(mainMod .. " + F12",                           hl.dsp.exec_cmd("~/.local/bin/workspace-stream leave"))

-- Focus with arrow keys / HJKL
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Window cycling
hl.bind(mainMod .. " + Tab",       hl.dsp.window.cycle_next())
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))

-- Workspace switching + move, collapsed into a loop (the old conf repeated these 10x).
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.exec_cmd("~/.local/bin/workspace-stream workspace " .. i))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
end

-- Move windows
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.exec_cmd("~/.local/bin/workspace-stream workspace m+1"))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.exec_cmd("~/.local/bin/workspace-stream workspace m-1"))

-- Volume and brightness controls (locked + repeating; was bindel)
hl.bind("XF86AudioRaiseVolume",   hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",   hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true })
hl.bind("XF86AudioMute",          hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",       hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",    hl.dsp.exec_cmd("brightnessctl s 10%+"),                             { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",  hl.dsp.exec_cmd("brightnessctl s 10%-"),                             { locked = true, repeating = true })

-- Media controls (locked, works even when locked; was bindl)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Mouse bindings
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

------------------
-- WINDOW RULES --
------------------

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "opaque-pixel-by-pixel",
    match = {
        class = ".*",
        title = "^(Pixel-by-Pixel).*",
    },
    opaque = true,
})

hl.window_rule({
    name  = "no-blur-pixel-by-pixel",
    match = { title = "^(Pixel-by-Pixel).*" },
    no_blur = true,
})

hl.window_rule({
    name  = "float-nmtui",
    match = { class = "^(nmtui-float)$" },
    float = true,
})

hl.window_rule({
    name  = "size-nmtui",
    match = { class = "^(nmtui-float)$" },
    size  = "600 450",
})

hl.window_rule({
    name  = "move-nmtui",
    match = { class = "^(nmtui-float)$" },
    move  = "(cursor_x - 300) (cursor_y + 30)",
})

-- OpenCode Hyprland popup (opencode-hyprland-popup.el)
-- Match on TITLE only -- the popup frame is titled "OpenCode Prompt",
-- which dodges the Emacs/emacs class-casing risk (RESEARCH sec.3).
hl.window_rule({
    name  = "float-opencode-prompt",
    match = { title = "^(OpenCode Prompt)$" },
    float = true,
})

hl.window_rule({
    name  = "size-opencode-prompt",
    match = { title = "^(OpenCode Prompt)$" },
    size  = "650 380",
})