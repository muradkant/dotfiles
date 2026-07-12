#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TARGET="$CONFIG_HOME/searxng"

mkdir -p -- "$TARGET"
chmod 700 "$TARGET"

if [[ ! -e "$TARGET/settings.yml" ]]; then
    secret="$(python3 -c 'import secrets; print(secrets.token_hex(32))')"
    sed "s/@SECRET_KEY@/$secret/" "$ROOT/settings.yml.in" >"$TARGET/settings.yml"
    chmod 600 "$TARGET/settings.yml"
    printf 'created %s/settings.yml\n' "$TARGET"
else
    printf 'preserved %s/settings.yml\n' "$TARGET"
fi
chmod 600 "$TARGET/settings.yml"

if [[ ! -e "$TARGET/limiter.toml" ]]; then
    install -m 600 "$ROOT/limiter.toml" "$TARGET/limiter.toml"
fi
chmod 600 "$TARGET/limiter.toml"
