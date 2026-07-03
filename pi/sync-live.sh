#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
exec "$script_dir/install.sh" --with-opencode --with-codex --with-philosophical "$@"
