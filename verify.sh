#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
failures=0

pass() { printf 'PASS %s\n' "$*"; }
fail() { printf 'FAIL %s\n' "$*" >&2; failures=$((failures + 1)); }

check_link() {
    local source="$1" destination="$2"
    if [[ -L "$destination" ]] &&
        [[ "$(readlink -f -- "$destination" 2>/dev/null || true)" == "$(readlink -f -- "$source")" ]]; then
        pass "${destination#"$HOME"/}"
    else
        fail "${destination#"$HOME"/} is not linked to repository source"
    fi
}

git -C "$ROOT" diff --check || fail "repository whitespace"
git -C "$ROOT" submodule status --recursive | while read -r state _; do
    [[ "$state" != -* && "$state" != +* && "$state" != U* ]]
done || fail "submodule revisions"

syntax_failures=0
for script in "$ROOT/install.sh" "$ROOT/verify.sh" "$ROOT"/bin/* \
    "$ROOT"/hypr/reload-* "$ROOT/hyprlauncher-ipc/build.sh"; do
    if ! bash -n "$script"; then
        fail "Bash syntax: ${script#"$ROOT"/}"
        syntax_failures=$((syntax_failures + 1))
    fi
done
((syntax_failures == 0)) && pass "Bash syntax"

check_link "$ROOT/.bashrc" "$HOME/.bashrc"
check_link "$ROOT/.bash_profile" "$HOME/.bash_profile"
check_link "$ROOT/.profile" "$HOME/.profile"
check_link "$ROOT/hypr/hyprland.lua" "$HOME/.config/hypr/hyprland.lua"
check_link "$ROOT/emacs/init.el" "$HOME/.emacs.d/init.el"
check_link "$ROOT/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"
check_link "$ROOT/nvim/nvim-pack-lock.json" "$HOME/.config/nvim/nvim-pack-lock.json"
check_link "$ROOT/bin/cliphist-picker" "$HOME/.local/bin/cliphist-picker"
check_link "$ROOT/bin/hyprlauncher-toggle" "$HOME/.local/bin/hyprlauncher-toggle"

if [[ "$(PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/bin command -v python3)" == /usr/bin/python3 ]]; then
    pass "distribution Python precedence"
else
    fail "distribution Python precedence"
fi

if PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/bin \
    /usr/bin/python3 /usr/bin/powerprofilesctl get >/dev/null 2>&1; then
    pass "powerprofilesctl system Python"
else
    fail "powerprofilesctl system Python"
fi

if command -v Hyprland >/dev/null 2>&1; then
    if Hyprland --verify-config --config "$ROOT/hypr/hyprland.lua" 2>&1 |
        grep -q 'config ok'; then
        pass "Hyprland tracked config"
    else
        fail "Hyprland tracked config"
    fi
fi

if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    errors="$(hyprctl configerrors)"
    if [[ -z "$errors" ]]; then
        pass "Hyprland config"
    else
        fail "Hyprland config: $errors"
    fi
fi

if command -v zellij >/dev/null 2>&1; then
    if zellij --config "$ROOT/zellij/config.kdl" setup --check >/dev/null 2>&1; then
        pass "Zellij config"
    else
        fail "Zellij config"
    fi
fi

if command -v nvim >/dev/null 2>&1; then
    if timeout 300s nvim --headless +qa >/dev/null 2>&1; then
        pass "Neovim config"
    else
        fail "Neovim config"
    fi
fi

if [[ -x "$HOME/.local/libexec/hyprlauncher-ipc" ]]; then
    if "$HOME/.local/libexec/hyprlauncher-ipc" --help 2>&1 | grep -q -- '--close'; then
        pass "Hyprlauncher close client"
    else
        fail "Hyprlauncher close client"
    fi
fi

if ((failures)); then
    printf '%d verification failure(s)\n' "$failures" >&2
    exit 1
fi
printf 'All portable dotfile checks passed.\n'
