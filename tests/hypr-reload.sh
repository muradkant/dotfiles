#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-hypr-reload.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

config="$ROOT/hypr/hyprland.lua"
monitors="$ROOT/hypr/config/monitors.lua"
rules="$ROOT/hypr/config/windowrules.lua"

grep -Fq 'require("config.windowrules")' "$config"
grep -Fq 'require("yt-stream-workspace")' "$config"
grep -Fq 'mirror   = "HDMI-A-1"' "$monitors"
grep -Fq 'name = "swash-overlay"' "$rules"
grep -Fq 'fullscreen_state = 2' "$rules"
grep -Fq 'sync_fullscreen = true' "$rules"
if sed -n '/name = "swash-overlay"/,/^})/p' "$rules" | grep -Fq 'no_anim'; then
    printf '%s\n' 'Swash animation is unexpectedly disabled' >&2
    exit 1
fi

bash -n "$ROOT/bin/swash-screenshot"
grep -Fq '$HOME/.local/bin/swash-screenshot' "$ROOT/noctalia/config.toml"

printf '%s\n' 'PASS current Hyprland, Noctalia, and animated Swash integration'
