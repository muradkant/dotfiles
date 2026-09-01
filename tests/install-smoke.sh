#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-install.XXXXXX")"
TEST_HOME="$TEST_ROOT/home"

cleanup() {
    rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

mkdir -p "$TEST_HOME"
printf 'original bashrc\n' >"$TEST_HOME/.bashrc"

export HOME="$TEST_HOME"
export XDG_CACHE_HOME="$TEST_HOME/.cache"
export XDG_CONFIG_HOME="$TEST_HOME/.config"
export XDG_DATA_HOME="$TEST_HOME/.local/share"
export XDG_STATE_HOME="$TEST_HOME/.local/state"
export DOTFILES_SKIP_SESSION_IMPORT=1
export DOTFILES_SKIP_PACKAGE_INSTALL=1
export DOTFILES_SKIP_SERVICE_BUILDS=1
export DOTFILES_SKIP_USER_SERVICES=1
unset HYPRLAND_INSTANCE_SIGNATURE

"$ROOT/install.sh" --streaming --controller --services
"$ROOT/verify.sh"

backup="$(find "$XDG_STATE_HOME/dotfiles/backups" -type f -name .bashrc -print -quit)"
[[ -n "$backup" ]]
[[ "$(sed -n '1p' "$backup")" == 'original bashrc' ]]
lock_target="$(readlink -f "$HOME/.config/nvim/nvim-pack-lock.json")"
[[ "$lock_target" == "$ROOT/nvim/nvim-pack-lock.json" ]]
[[ ! -L "$HOME/.config/yt-stream-workspace/config" ]]
[[ "$(stat -c %a "$HOME/.config/yt-stream-workspace/config")" == 600 ]]
# Match the literal runtime expression copied from the component template.
# shellcheck disable=SC2016
grep -Fqx 'YTWS_WALLPAPER="$HOME/Pictures/background.jpg"' \
    "$HOME/.config/yt-stream-workspace/config"
[[ -e "$HOME/Pictures/background.jpg" ]]
[[ -L "$HOME/.config/containers/systemd/searxng.container" ]]
[[ "$(stat -c %a "$HOME/.config/searxng/settings.yml")" == 600 ]]
[[ "$(readlink -f "$HOME/.config/noctalia/config.toml")" == "$ROOT/noctalia/config.toml" ]]
[[ "$(readlink -f "$HOME/.config/swash/settings.ini")" == "$ROOT/swash/settings.ini" ]]
[[ "$(readlink -f "$HOME/.config/herdr/config.toml")" == "$ROOT/herdr/config.toml" ]]
[[ "$(readlink -f "$HOME/.local/bin/swash-screenshot")" == "$ROOT/bin/swash-screenshot" ]]
controller_target="$(readlink -f "$HOME/.local/bin/controller-mouse-game-guard")"
expected_controller="$ROOT/components/linux-zhixu-controller-fix/scripts/controller-mouse-game-guard"
[[ "$controller_target" == "$expected_controller" ]]
printf '\n# preserved user edit\n' >>"$HOME/.config/yt-stream-workspace/config"

"$ROOT/install.sh" --streaming --controller --services
"$ROOT/verify.sh"

[[ "$(find "$XDG_STATE_HOME/dotfiles/backups" -type f -name .bashrc | wc -l)" == 1 ]]
grep -q '^# preserved user edit$' "$HOME/.config/yt-stream-workspace/config"

printf 'PASS isolated install, backup, idempotent rerun, and verification\n'
