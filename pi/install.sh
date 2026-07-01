#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
target_home="${HOME}"
install_packages=1
with_opencode=0
with_philosophical=0

usage() {
	cat <<'EOF'
Usage: install.sh [options]

Options:
  --home PATH            Install under another home directory
  --skip-packages        Do not install the pinned Pi packages
  --with-opencode        Also install matching OpenCode agents
  --with-philosophical   Also synchronize ~/Philosophical/outputs
  -h, --help             Show this help
EOF
}

while (($# > 0)); do
	case "$1" in
		--home)
			shift
			(($# > 0)) || { echo "--home requires a path" >&2; exit 2; }
			target_home="$1"
			;;
		--skip-packages)
			install_packages=0
			;;
		--with-opencode)
			with_opencode=1
			;;
		--with-philosophical)
			with_philosophical=1
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			echo "Unknown argument: $1" >&2
			usage >&2
			exit 2
			;;
	esac
	shift
done

command -v node >/dev/null || { echo "node is required" >&2; exit 1; }
command -v pi >/dev/null || { echo "Install Pi before applying this profile" >&2; exit 1; }

mkdir -p "$target_home"
target_home="$(cd -- "$target_home" && pwd -P)"
agent_dir="$target_home/.pi/agent"
extension_dir="$agent_dir/extensions"
mkdir -p "$extension_dir"

pi_executable="$(command -v pi)"
pi_realpath="$(realpath "$pi_executable")"
pi_package_root="$(dirname -- "$(dirname -- "$pi_realpath")")"
preset_source="$pi_package_root/examples/extensions/preset.ts"

if [[ ! -f "$pi_package_root/package.json" ]] ||
	! node -e 'const p=require(process.argv[1]); process.exit(p.name === "@earendil-works/pi-coding-agent" ? 0 : 1)' \
		"$pi_package_root/package.json"; then
	echo "Could not locate @earendil-works/pi-coding-agent from $pi_executable" >&2
	exit 1
fi
if [[ ! -f "$preset_source" ]]; then
	echo "Installed Pi does not include examples/extensions/preset.ts" >&2
	echo "Install the npm release documented in $script_dir/README.md" >&2
	exit 1
fi

backup_dir=""
backup_if_changed() {
	local source="$1"
	local destination="$2"
	local relative="$3"

	[[ -e "$destination" ]] || return 0
	cmp -s "$source" "$destination" && return 0
	if [[ -z "$backup_dir" ]]; then
		backup_dir="$agent_dir/backups/dotfiles-$(date +%Y%m%d-%H%M%S)"
	fi
	mkdir -p "$backup_dir/$(dirname -- "$relative")"
	cp -a -- "$destination" "$backup_dir/$relative"
}

install_managed_file() {
	local source="$1"
	local destination="$2"
	local relative="$3"
	backup_if_changed "$source" "$destination" "$relative"
	install -D -m 0644 -- "$source" "$destination"
}

temporary_presets="$(mktemp)"
trap 'rm -f -- "$temporary_presets"' EXIT
node "$script_dir/scripts/render-presets.mjs" "$temporary_presets"

install_managed_file "$script_dir/agent/settings.json" "$agent_dir/settings.json" "settings.json"
install_managed_file "$script_dir/agent/all-tools.ts" "$agent_dir/all-tools.ts" "all-tools.ts"
install_managed_file "$preset_source" "$extension_dir/preset.ts" "extensions/preset.ts"
install_managed_file "$temporary_presets" "$agent_dir/presets.json" "presets.json"

web_config="$target_home/.pi/web-search.json"
if [[ ! -e "$web_config" ]]; then
	install -D -m 0600 -- "$script_dir/web-search.json" "$web_config"
fi

if ((with_opencode)); then
	opencode_agents="$target_home/.config/opencode/agents"
	install -D -m 0644 -- "$script_dir/profiles/Rust Analyst.md" "$opencode_agents/Rust Analyst.md"
	install -D -m 0644 -- "$script_dir/profiles/Brainstormer.md" "$opencode_agents/Brainstormer.md"
fi

if ((with_philosophical)); then
	philosophical_outputs="$target_home/Philosophical/outputs"
	install -D -m 0644 -- "$script_dir/profiles/Rust Analyst.md" "$philosophical_outputs/Rust Analyst.md"
	install -D -m 0644 -- "$script_dir/profiles/Brainstormer.md" "$philosophical_outputs/SOUL.md"
fi

if ((install_packages)); then
	while IFS= read -r package; do
		HOME="$target_home" PI_CODING_AGENT_DIR="$agent_dir" pi install "$package"
	done < <(node -e 'const s=require(process.argv[1]); for (const p of s.packages) console.log(typeof p === "string" ? p : p.source)' \
		"$script_dir/agent/settings.json")

	browse_version="$(node -e 'process.stdout.write(require(process.argv[1]).browse)' \
		"$script_dir/external-tools.json")"
	browse_prefix="$target_home/.local/share/muradkant-pi-profile/browse"
	npm install \
		--prefix "$browse_prefix" \
		--ignore-scripts \
		"browse@$browse_version"

	browse_package_root="$browse_prefix/node_modules/browse"
	browse_skill_source="$browse_package_root/skills/browse/SKILL.md"
	if [[ ! -f "$browse_skill_source" ]]; then
		echo "Pinned Browse CLI does not contain its bundled skill" >&2
		exit 1
	fi
	shared_browse_skill="$target_home/.agents/skills/browse/SKILL.md"
	install_managed_file \
		"$browse_skill_source" \
		"$shared_browse_skill" \
		"shared-skills/browse/SKILL.md"

	pi_browse_skill="$agent_dir/skills/browse"
	expected_browse_link="../../../.agents/skills/browse"
	if [[ -e "$pi_browse_skill" || -L "$pi_browse_skill" ]]; then
		if [[ ! -L "$pi_browse_skill" ]] ||
			[[ "$(readlink "$pi_browse_skill")" != "$expected_browse_link" ]]; then
			if [[ -z "$backup_dir" ]]; then
				backup_dir="$agent_dir/backups/dotfiles-$(date +%Y%m%d-%H%M%S)"
			fi
			mkdir -p "$backup_dir/skills"
			cp -a -- "$pi_browse_skill" "$backup_dir/skills/browse"
			rm -rf -- "$pi_browse_skill"
		fi
	fi
	mkdir -p "$agent_dir/skills"
	if [[ ! -L "$pi_browse_skill" ]]; then
		ln -s "$expected_browse_link" "$pi_browse_skill"
	fi

	browse_executable="$target_home/.local/bin/browse"
	expected_browse_executable_link="../share/muradkant-pi-profile/browse/node_modules/browse/bin/run.js"
	if [[ -e "$browse_executable" || -L "$browse_executable" ]]; then
		if [[ ! -L "$browse_executable" ]] ||
			[[ "$(readlink "$browse_executable")" != "$expected_browse_executable_link" ]]; then
			if [[ -z "$backup_dir" ]]; then
				backup_dir="$agent_dir/backups/dotfiles-$(date +%Y%m%d-%H%M%S)"
			fi
			mkdir -p "$backup_dir/bin"
			cp -a -- "$browse_executable" "$backup_dir/bin/browse"
			rm -f -- "$browse_executable"
		fi
	fi
	mkdir -p "$(dirname -- "$browse_executable")"
	if [[ ! -L "$browse_executable" ]]; then
		ln -s "$expected_browse_executable_link" "$browse_executable"
	fi
fi

verify_args=(--home "$target_home")
((install_packages)) && verify_args+=(--require-packages)
node "$script_dir/scripts/verify.mjs" "${verify_args[@]}"

if [[ -n "$backup_dir" ]]; then
	echo "Previous managed files backed up under $backup_dir"
fi
echo "Pi profile installed under $agent_dir"
if [[ ! -x "$(command -v rustup 2>/dev/null || true)" ]]; then
	echo "Optional Rust support: install rustup, then add rust-analyzer rust-docs clippy rustfmt"
fi
