#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
profile_root="$(dirname -- "$script_dir")"
name="${PI_PROFILE_TEST_BOX:-pi-profile-test}"
image="${PI_PROFILE_TEST_IMAGE:-docker.io/library/node:22-bookworm}"
box_home="$(mktemp -d)"

cleanup() {
	distrobox rm --force "$name" >/dev/null 2>&1 || true
	rm -rf -- "$box_home"
}
trap cleanup EXIT

command -v distrobox >/dev/null || { echo "distrobox is required" >&2; exit 1; }
if distrobox list 2>/dev/null | awk 'NR > 1 {print $3}' | grep -Fxq "$name"; then
	echo "Distrobox already exists: $name" >&2
	exit 1
fi

distrobox create --yes \
	--name "$name" \
	--image "$image" \
	--home "$box_home" \
	--volume "$profile_root:/opt/muradkant-pi-profile:ro"

# The quoted program runs inside the container; expansion here would be wrong.
# shellcheck disable=SC2016
distrobox enter "$name" -- bash -lc '
	set -euo pipefail
	export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
	curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs |
		sh -s -- -y --profile minimal \
			--component rust-analyzer,rust-docs,clippy,rustfmt
	/opt/muradkant-pi-profile/install.sh --with-opencode --with-codex
	/opt/muradkant-pi-profile/tests/smoke.sh "$HOME"
	/opt/muradkant-pi-profile/tests/codex-profiles.sh "$HOME"
	rust-analyzer --version
	installed_components="$(rustup component list --installed)"
	for component in rust-analyzer rust-docs clippy rustfmt; do
		grep -q "^${component}-" <<<"$installed_components" || {
			echo "Missing Rust component: $component" >&2
			printf "%s\n" "$installed_components" >&2
			exit 1
		}
	done
	if [[ -e "$HOME/.pi/agent/auth.json" ]]; then
		node -e '\''
			const fs = require("fs");
			const auth = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
			if (Object.keys(auth).length !== 0) {
				throw new Error("Unexpected credential entries in disposable auth.json");
			}
		'\'' "$HOME/.pi/agent/auth.json"
	fi
	if [[ -d "$HOME/.pi/agent/sessions" ]] &&
		find "$HOME/.pi/agent/sessions" -type f -print -quit | grep -q .; then
		echo "Unexpected saved session in disposable home" >&2
		exit 1
	fi
'

echo "Disposable Distrobox installation test passed"
