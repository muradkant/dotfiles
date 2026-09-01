#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-bash-startup.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

mkdir -p "$TMP/home/.local/share" "$TMP/home/.local/bin"
ln -s "$ROOT/bin/env" "$TMP/home/.local/bin/env"

HOME="$TMP/home" PATH="/usr/bin" \
    bash --noprofile --rcfile "$ROOT/.bashrc" -ic \
    'case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) exit 1 ;; esac'

printf '%s\n' 'PASS fresh interactive Bash loads the current local-bin environment'
