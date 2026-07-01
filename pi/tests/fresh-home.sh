#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
profile_root="$(dirname -- "$script_dir")"
temporary_root="$(mktemp -d)"
trap 'rm -rf -- "$temporary_root"' EXIT
fresh_home="$temporary_root/home"
mkdir -p "$fresh_home"

"$profile_root/install.sh" --home "$fresh_home" --with-opencode

[[ ! -e "$fresh_home/.pi/agent/auth.json" ]]
[[ ! -e "$fresh_home/.pi/agent/sessions" ]]
[[ -f "$fresh_home/.config/opencode/agents/Rust Analyst.md" ]]
[[ -f "$fresh_home/.config/opencode/agents/Brainstormer.md" ]]

"$script_dir/smoke.sh" "$fresh_home"
echo "Fresh-home installation test passed"
