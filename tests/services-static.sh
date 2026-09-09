#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-services.XXXXXX")"
server_pid=""

cleanup() {
    [[ -z "$server_pid" ]] || kill "$server_pid" >/dev/null 2>&1 || true
    rm -rf -- "$TMP"
}
trap cleanup EXIT

for script in "$ROOT/files/bin/wait-for-tcp" "$ROOT/services/kokoro/install.sh" \
    "$ROOT/services/searxng/install.sh"; do
    bash -n "$script"
done

grep -q '^version = "2.12.0+cpu"$' "$ROOT/services/kokoro/uv.lock"
if grep -q '^name = "nvidia-' "$ROOT/services/kokoro/uv.lock"; then
    printf 'CUDA package leaked into the CPU service lock\n' >&2
    exit 1
fi

port="$(python3 - <<'PY'
import socket
with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
)"
python3 -m http.server "$port" --bind 127.0.0.1 \
    >"$TMP/http.log" 2>&1 &
server_pid=$!
"$ROOT/files/bin/wait-for-tcp" 127.0.0.1 "$port" 5
if "$ROOT/files/bin/wait-for-tcp" 127.0.0.1 1 1; then
    printf 'hard TCP timeout unexpectedly succeeded\n' >&2
    exit 1
fi
"$ROOT/files/bin/wait-for-tcp" 127.0.0.1 1 1 --soft

HOME="$TMP/home" XDG_CONFIG_HOME="$TMP/config" \
    "$ROOT/services/searxng/install.sh"
settings="$TMP/config/searxng/settings.yml"
[[ "$(stat -c %a "$settings")" == 600 ]]
if grep -q '@SECRET_KEY@' "$settings"; then
    printf 'SearXNG secret placeholder was not replaced\n' >&2
    exit 1
fi
printf '\n# keep\n' >>"$settings"
chmod 644 "$settings" "$TMP/config/searxng/limiter.toml"
HOME="$TMP/home" XDG_CONFIG_HOME="$TMP/config" \
    "$ROOT/services/searxng/install.sh"
grep -q '^# keep$' "$settings"
[[ "$(stat -c %a "$settings")" == 600 ]]
[[ "$(stat -c %a "$TMP/config/searxng/limiter.toml")" == 600 ]]

mkdir -p "$TMP/units" "$TMP/config/containers/systemd"
for unit in "$ROOT"/systemd/user/*.service; do
    sed \
        -e 's|%h/.local/bin/wait-for-tcp|/usr/bin/true|' \
        -e 's|%h/.local/share/dotfiles/services/kokoro/venv/bin/python|/usr/bin/true|' \
        "$unit" >"$TMP/units/${unit##*/}"
done
systemd-analyze --user verify "$TMP"/units/*.service

ln -s "$ROOT/services/searxng/searxng.container" \
    "$TMP/config/containers/systemd/searxng.container"
HOME="$TMP/home" XDG_CONFIG_HOME="$TMP/config" \
    /usr/lib/systemd/user-generators/podman-user-generator -user -dryrun \
    >"$TMP/quadlet.out" 2>&1
grep -q 'sha256:1a9d213' "$TMP/quadlet.out"
grep -q -- '--security-opt=no-new-privileges' "$TMP/quadlet.out"

printf 'PASS service scripts, CPU lock, units, secret generation, and Quadlet\n'
