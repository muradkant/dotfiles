#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
profile_root="$(dirname -- "$script_dir")"
temporary_root="$(mktemp -d)"
trap 'rm -rf -- "$temporary_root"' EXIT
fresh_home="$temporary_root/home"
mkdir -p "$fresh_home/.config/devin/skills" "$fresh_home/.config/goose/skills"
ln -s ../../../../../tmp/absent-skill "$fresh_home/.config/devin/skills/browse"
ln -s ../../../../../tmp/absent-skill "$fresh_home/.config/goose/skills/browse"

"$profile_root/install.sh" --home "$fresh_home" --with-opencode --with-codex

[[ ! -e "$fresh_home/.pi/agent/auth.json" ]]
[[ ! -e "$fresh_home/.pi/agent/sessions" ]]
[[ -f "$fresh_home/.config/opencode/agents/Rust Analyst.md" ]]
[[ -f "$fresh_home/.config/opencode/agents/Brainstormer.md" ]]
[[ -f "$fresh_home/.codex/rust-analyst.config.toml" ]]
[[ -f "$fresh_home/.codex/brainstormer.config.toml" ]]
[[ -f "$fresh_home/.codex/systems-analyst.config.toml" ]]
for client in devin goose; do
	link="$fresh_home/.config/$client/skills/browse"
	[[ "$(readlink "$link")" == '../../../.agents/skills/browse' ]]
	cmp -s "$link/SKILL.md" "$fresh_home/.agents/skills/browse/SKILL.md"
done
for tool in pi opencode codex; do
	version="$(node -e "process.stdout.write(require(process.argv[1]).$tool)" \
		"$profile_root/external-tools.json")"
	actual="$("$fresh_home/.local/bin/$tool" --version)"
	expected="$version"
	[[ "$tool" != codex ]] || expected="codex-cli $version"
	[[ "$actual" == "$expected" ]]
done

"$script_dir/smoke.sh" "$fresh_home"
CODEX_BIN="$fresh_home/.local/bin/codex" \
	"$script_dir/codex-profiles.sh" "$fresh_home"
echo "Fresh-home installation test passed"
