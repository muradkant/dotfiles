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
unset HYPRLAND_INSTANCE_SIGNATURE

"$ROOT/install.sh"
"$ROOT/verify.sh"

backup="$(find "$XDG_STATE_HOME/dotfiles/backups" -type f -name .bashrc -print -quit)"
[[ -n "$backup" ]]
[[ "$(sed -n '1p' "$backup")" == 'original bashrc' ]]
lock_target="$(readlink -f "$HOME/.config/nvim/nvim-pack-lock.json")"
[[ "$lock_target" == "$ROOT/nvim/nvim-pack-lock.json" ]]

close_client="$HOME/.local/libexec/hyprlauncher-ipc"
before="$(stat -c '%Y:%s' "$close_client")"
"$ROOT/install.sh"
"$ROOT/verify.sh"
after="$(stat -c '%Y:%s' "$close_client")"

[[ "$before" == "$after" ]]
[[ "$(find "$XDG_STATE_HOME/dotfiles/backups" -type f -name .bashrc | wc -l)" == 1 ]]

printf 'PASS isolated install, backup, idempotent rerun, and verification\n'
