#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-hypr-reload.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

config="$ROOT/hypr/hyprland.conf"
grep -Fqx 'monitor = HDMI-A-1, 1920x1080@60, 1280x0, 1.5' "$config"
grep -Fqx 'source = ~/.config/hypr/workspaces-hdmi-extended.conf' "$config"
if grep -Eq '^[[:space:]]*monitor[[:space:]]*=.*HDMI-A-1.*mirror' "$config"; then
    printf '%s\n' 'mirror and extended HDMI rules are active together' >&2
    exit 1
fi

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
