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

for script in "$ROOT/bin/hermes-cdp-browser" "$ROOT/bin/signal-cli-http" \
    "$ROOT/bin/wait-for-tcp" "$ROOT/services/kokoro/install.sh" \
    "$ROOT/services/searxng/install.sh"; do
    bash -n "$script"
done

grep -q '^version = "2.12.0+cpu"$' "$ROOT/services/kokoro/uv.lock"
if grep -q '^name = "nvidia-' "$ROOT/services/kokoro/uv.lock"; then
    printf 'CUDA package leaked into the CPU service lock\n' >&2
    exit 1
fi

mock="$TMP/chrome"
cat >"$mock" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$@"
MOCK
chmod +x "$mock"
args="$(HOME="$TMP/home" HERMES_CHROMIUM_BIN="$mock" \
    "$ROOT/bin/hermes-cdp-browser")"
grep -Fqx -- '--remote-debugging-port=9223' <<<"$args"
grep -Fqx -- '--remote-debugging-address=127.0.0.1' <<<"$args"

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
"$ROOT/bin/wait-for-tcp" 127.0.0.1 "$port" 5
if "$ROOT/bin/wait-for-tcp" 127.0.0.1 1 1; then
    printf 'hard TCP timeout unexpectedly succeeded\n' >&2
    exit 1
fi
"$ROOT/bin/wait-for-tcp" 127.0.0.1 1 1 --soft

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
for unit in "$ROOT"/systemd/user/*.service "$ROOT"/systemd/user/*.socket; do
    sed \
        -e 's|%h/.local/bin/hermes-cdp-browser|/usr/bin/true|' \
        -e 's|%h/.local/bin/wait-for-tcp|/usr/bin/true|' \
        -e 's|%h/.local/bin/signal-cli-http|/usr/bin/true|' \
        -e 's|%h/.hermes/hermes-agent/venv/bin/python|/usr/bin/true|' \
        -e 's|%h/.local/share/dotfiles/services/kokoro/venv/bin/python|/usr/bin/true|' \
        "$unit" >"$TMP/units/${unit##*/}"
done
cat >"$TMP/units/hermes-gateway.service" <<'UNIT'
[Service]
ExecStart=/usr/bin/true
UNIT
mkdir -p "$TMP/units/hermes-gateway.service.d"
sed 's|%h/.local/bin/wait-for-tcp|/usr/bin/true|' \
    "$ROOT/systemd/user/hermes-gateway.service.d/10-dotfiles.conf" \
    >"$TMP/units/hermes-gateway.service.d/10-dotfiles.conf"
systemd-analyze --user verify "$TMP"/units/*.service "$TMP"/units/*.socket

ln -s "$ROOT/services/searxng/searxng.container" \
    "$TMP/config/containers/systemd/searxng.container"
HOME="$TMP/home" XDG_CONFIG_HOME="$TMP/config" \
    /usr/lib/systemd/user-generators/podman-user-generator -user -dryrun \
    >"$TMP/quadlet.out" 2>&1
grep -q 'sha256:1a9d213' "$TMP/quadlet.out"
grep -q -- '--security-opt=no-new-privileges' "$TMP/quadlet.out"

printf 'PASS service scripts, CPU lock, units, secret generation, and Quadlet\n'
