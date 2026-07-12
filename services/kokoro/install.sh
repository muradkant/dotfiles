#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DATA_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/services/kokoro"
VENV="$DATA_ROOT/venv"
MODEL_DIR="$DATA_ROOT/model"
SKIP_MODEL=0

[[ "${1:-}" != --skip-model ]] || SKIP_MODEL=1
command -v uv >/dev/null 2>&1 || {
    printf 'kokoro install: uv is required\n' >&2
    exit 1
}

UV_PROJECT_ENVIRONMENT="$VENV" uv sync --frozen --no-dev --project "$ROOT"

if ((SKIP_MODEL == 0)); then
    revision="$(tr -d '[:space:]' <"$ROOT/model-revision")"
    "$VENV/bin/python" - "$MODEL_DIR" "$revision" <<'PY'
import sys
from huggingface_hub import snapshot_download

snapshot_download(
    repo_id="hexgrad/Kokoro-82M",
    revision=sys.argv[2],
    local_dir=sys.argv[1],
    allow_patterns=["config.json", "kokoro-v1_0.pth", "voices/*.pt"],
)
PY
fi

printf 'Kokoro environment installed under %s\n' "$DATA_ROOT"
