-- Display layout: two modes, mutually exclusive. Keep EXACTLY ONE fenced block
-- uncommented, then `hyprctl reload`.
--
--   MODE A  MIRROR    (currently ON)  — big HDMI-A-2 mirrors your small HDMI-A-1.
--   MODE B  EXTENDED  (commented out) — two independent screens; the big one gets
--                                       its own exclusive workspaces 6-10, the
--                                       small one keeps 1-5.
--
-- To switch: comment the block of the mode you're on, uncomment the other, reload.

-- ==================== MODE A — MIRROR (ON) ====================
-- hl.monitor({
--     output   = "HDMI-A-1",
--     mode     = "1920x1080@60",
--     position = "0x0",
--     scale    = 1,
-- })
-- hl.monitor({
--     output   = "HDMI-A-2",         -- big screen mirrors your small screen
--     mode     = "1920x1080@60",
--     position = "auto",
--     scale    = 1,
--     mirror   = "HDMI-A-1",
-- })
-- ==================== /MODE A ====================


-- ==================== MODE B — EXTENDED (OFF, commented) ====================
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = 1,
})
-- Big screen as its own monitor, right of the small one (4K native; raise
-- `scale` to 1.5-2 if text looks too small).
hl.monitor({
    output   = "HDMI-A-2",
    mode     = "3840x2160@30",
    position = "1920x0",
    scale    = 1.5,
})
-- Exclusive workspaces: small 1-5, big 6-10.
hl.workspace_rule({ workspace = "1",  monitor = "HDMI-A-1", default = true, persistent = true })
hl.workspace_rule({ workspace = "2",  monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "3",  monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "4",  monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "5",  monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "6",  monitor = "HDMI-A-2", default = true, persistent = true })
hl.workspace_rule({ workspace = "7",  monitor = "HDMI-A-2", persistent = true })
hl.workspace_rule({ workspace = "8",  monitor = "HDMI-A-2", persistent = true })
hl.workspace_rule({ workspace = "9",  monitor = "HDMI-A-2", persistent = true })
hl.workspace_rule({ workspace = "10", monitor = "HDMI-A-2", persistent = true })
-- ==================== /MODE B ====================
