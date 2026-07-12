#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
profile_root="$(dirname -- "$script_dir")"
target_home="${1:-$HOME}"
target_home="$(cd -- "$target_home" && pwd -P)"
pi_executable="$target_home/.local/bin/pi"
[[ -x "$pi_executable" ]] || pi_executable="$(command -v pi)"

node "$profile_root/scripts/verify.mjs" --home "$target_home" --require-packages
"$target_home/.local/bin/browse" --version

temporary_dir="$(mktemp -d)"
trap 'rm -rf -- "$temporary_dir"' EXIT

run_probe() {
	local name="$1"
	shift
	local probe_file="$temporary_dir/$name-tools.json"
	local rpc_file="$temporary_dir/$name-rpc.jsonl"
	local error_file="$temporary_dir/$name-stderr.log"

	printf '%s\n' '{"id":"state","type":"get_state"}' |
		HOME="$target_home" \
		PI_PROFILE_PROBE="$probe_file" \
		PI_LENS_TEST_MODE=1 \
		timeout 45 "$pi_executable" --offline --no-session --mode rpc \
			--preset "Rust Analyst" \
			-e "$script_dir/probe.ts" \
			"$@" >"$rpc_file" 2>"$error_file"

	[[ -s "$probe_file" ]] || {
		echo "Tool probe did not run ($name)" >&2
		cat "$error_file" >&2
		exit 1
	}
	node -e '
		const fs = require("fs");
		const records = fs.readFileSync(process.argv[1], "utf8").trim().split("\n").filter(Boolean).map(JSON.parse);
		if (!records.some((record) => record.type === "response" && record.command === "get_state" && record.success)) {
			throw new Error("Pi RPC state probe failed");
		}
	' "$rpc_file"
	echo "$probe_file"
}

normal_probe="$(run_probe normal)"
# The JavaScript template literal is not a shell expansion.
# shellcheck disable=SC2016
node -e '
	const fs = require("fs");
	const probe = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
	const expected = [
		"ast_dump", "ast_grep_dump", "ast_grep_outline", "ast_grep_replace", "ast_grep_search",
		"bash", "edit", "fetch_content", "find", "get_search_content", "grep", "lens_diagnostics",
		"ls", "lsp_diagnostics", "lsp_navigation", "module_report", "read", "read_enclosing",
		"read_symbol", "symbol_search", "web_search", "write",
	].sort();
	if (JSON.stringify(probe.activeTools) !== JSON.stringify(expected)) {
		throw new Error(`Unexpected active tools:\n${JSON.stringify(probe.activeTools, null, 2)}`);
	}
	if (JSON.stringify(probe.allTools) !== JSON.stringify(expected)) {
		throw new Error(`Unexpected registered tools:\n${JSON.stringify(probe.allTools, null, 2)}`);
	}
' "$normal_probe"

restricted_probe="$(run_probe restricted --tools read)"
# The JavaScript template literal is not a shell expansion.
# shellcheck disable=SC2016
node -e '
	const fs = require("fs");
	const probe = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
	if (JSON.stringify(probe.activeTools) !== JSON.stringify(["read"])) {
		throw new Error(`Explicit --tools restriction was not preserved: ${JSON.stringify(probe.activeTools)}`);
	}
' "$restricted_probe"

echo "Pi runtime smoke test passed with all 22 tools and explicit CLI restriction preservation"
