#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="$repo_root/components/hyprlauncher"
build_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-build/hyprlauncher"
destination="${1:-$HOME/.local/libexec/hyprlauncher-ipc}"

[[ -f "$source_dir/CMakeLists.txt" ]] || {
    printf 'hyprlauncher submodule is missing; run git submodule update --init\n' >&2
    exit 1
}

mkdir -p "$build_dir" "$(dirname -- "$destination")"

# The login environment may still contain the pre-fix Homebrew-first PATH on
# the first installation. Do not let it select incompatible build metadata.
env PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/bin \
    /usr/bin/cmake -S "$source_dir" -B "$build_dir" \
    -DCMAKE_BUILD_TYPE=Release \
    -DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config
env PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/bin \
    /usr/bin/cmake --build "$build_dir" --parallel 2

install -Dm755 "$build_dir/hyprlauncher" "$destination"
"$destination" --help | grep -q -- '--close'
printf 'installed %s\n' "$destination"
