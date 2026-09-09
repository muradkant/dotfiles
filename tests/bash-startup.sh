#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-bash-startup.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

# The managed ~/.bashrc (owned by `home-manager switch --flake "$ROOT"`)
# must bring $HOME/.local/bin onto PATH for fresh interactive shells.
# $HOME is pointed at a disposable dir so the assertion covers the
# dynamic session PATH, not leftovers from the current environment.
mkdir -p "$TMP/home"
HOME="$TMP/home" PATH="/usr/bin:/bin" \
    bash --noprofile --rcfile "$HOME/.bashrc" -ic \
    'case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) exit 1 ;; esac'

printf '%s\n' 'PASS fresh interactive Bash loads the Home Manager session PATH'
