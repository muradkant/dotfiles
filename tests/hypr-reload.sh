#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-hypr-reload.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

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

printf '%s\n' 'PASS HDMI recovery uses the portable JPG wallpaper path'
