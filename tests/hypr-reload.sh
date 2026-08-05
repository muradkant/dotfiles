#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-hypr-reload.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

config="$ROOT/hypr/hyprland.lua"
module="$ROOT/hypr/workspaces-hdmi-extended.lua"
# Mirror mode is active on HDMI-A-1.
grep -Fxq '    mirror   = "eDP-1",' "$config"
grep -Fxq -e '-- hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "1280x0", scale = 1.5 })' "$config"
# The extended HDMI monitor and its workspace module must stay non-active.
if ! grep -Fq 'require("workspaces-hdmi-extended")' "$config"; then
    printf '%s\n' 'unable to find the extended-HDMI require switch' >&2
    exit 1
fi
if grep -Eq '^[[:space:]]*hl\.monitor\({.*"HDMI-A-1".*1280x0' "$config" ||
   grep -Eyq '^[[:space:]]*require\("workspaces-hdmi-extended"\)' "$config"; then
    printf '%s\n' 'mirror and extended HDMI rules are active together' >&2
    exit 1
fi
grep -Fq 'workspace_rule' "$module"
grep -Fq 'reload-hdmi-extended' "$module"
grep -Fq 'eDP-1' "$module"
grep -Fq 'HDMI-A-1' "$module"

mkdir -p "$TMP/bin" "$TMP/home with space/Pictures"
for command in hyprctl pkill sleep; do
    ln -s mock "$TMP/bin/$command"
done
cat >"$TMP/bin/mock" <<'MOCK'
#!/usr/bin/env bash
printf '%s' "${0##*/}" >>"$MOCK_LOG"
printf ' <%s>' "$@" >>"$MOCK_LOG"
printf '\n' >>"$MOCK_LOG"
MOCK
chmod +x "$TMP/bin/mock"

HOME="$TMP/home with space" PATH="$TMP/bin:/usr/bin" MOCK_LOG="$TMP/calls" \
    "$ROOT/hypr/reload-hdmi-extended"

[[ "$(grep -c '^hyprctl ' "$TMP/calls")" == 4 ]]
[[ "$(grep -c '^sleep ' "$TMP/calls")" == 2 ]]
grep -F 'home with space/Pictures/background.jpg' "$TMP/calls" >/dev/null
if grep -Eq '/home/muradkant|background\.png' "$TMP/calls"; then
    printf '%s\n' 'nonportable wallpaper path reached Hyprland' >&2
    exit 1
fi

printf '%s\n' 'PASS exclusive extended HDMI mode and portable recovery path'
