#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
profile_root="$(dirname -- "$script_dir")"
target_home="${1:-$HOME}"
target_home="$(cd -- "$target_home" && pwd -P)"
codex_bin="${CODEX_BIN:-codex}"

command -v "$codex_bin" >/dev/null || {
	echo "Codex CLI is required for the Codex profile runtime test" >&2
	exit 1
}

node "$profile_root/scripts/verify.mjs" \
	--home "$target_home" \
	--require-codex-profiles

temporary_dir="$(mktemp -d)"
trap 'rm -rf -- "$temporary_dir"' EXIT

verify_profile() {
	local slug="$1"
	local source="$2"
	local prompt_output="$temporary_dir/$slug.json"

	CODEX_HOME="$target_home/.codex" \
		"$codex_bin" --profile "$slug" \
		debug prompt-input "Codex profile verification probe" >"$prompt_output"

	node - "$profile_root/profiles/$source" "$prompt_output" <<'NODE'
const fs = require("fs");

const expected = fs.readFileSync(process.argv[2], "utf8");
const prompt = JSON.parse(fs.readFileSync(process.argv[3], "utf8"));

function containsExpected(value) {
	if (typeof value === "string") return value.includes(expected);
	if (Array.isArray(value)) return value.some(containsExpected);
	if (value && typeof value === "object") {
		return Object.values(value).some(containsExpected);
	}
	return false;
}

if (!containsExpected(prompt)) {
	throw new Error("Canonical profile was absent from Codex's model-visible prompt input");
}
NODE
}

verify_profile rust-analyst "Rust Analyst.md"
verify_profile brainstormer "Brainstormer.md"
verify_profile systems-analyst "Systems Analyst.md"

echo "Codex runtime test passed: all three canonical profiles reached the model-visible prompt"
