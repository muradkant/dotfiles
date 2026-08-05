-- Extended HDMI workspace bindings (Lua).
-- Laptop panel: 1-5. HDMI monitor: 6-10.
-- Require it from hyprland.lua after declaring the HDMI-A-1 monitor, e.g.:
--   require("workspaces-hdmi-extended")

hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/reload-hdmi-extended")
end)

hl.workspace_rule({ workspace = "1",  monitor = "eDP-1",    default = true })
hl.workspace_rule({ workspace = "2",  monitor = "eDP-1" })
hl.workspace_rule({ workspace = "3",  monitor = "eDP-1" })
hl.workspace_rule({ workspace = "4",  monitor = "eDP-1" })
hl.workspace_rule({ workspace = "5",  monitor = "eDP-1" })
hl.workspace_rule({ workspace = "6",  monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "7",  monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "8",  monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "9",  monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "10", monitor = "HDMI-A-1" })