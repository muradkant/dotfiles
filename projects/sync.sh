#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK="${PROJECT_LOCK_FILE:-$ROOT/projects/lock.json}"
TARGET_HOME="${PROJECT_TARGET_HOME:-$HOME}"
MODE=check
GROUP=all

usage() {
    cat <<'EOF'
Usage: projects/sync.sh [--materialize] [--group runtime|project|reference|all]

Check pinned standalone repositories. --materialize clones missing entries at
their locked revisions; existing repositories are never fetched or checked out.
EOF
}

while (($#)); do
    case "$1" in
        --materialize) MODE=materialize ;;
        --group)
            shift
            (($#)) || { printf '%s\n' '--group requires a value' >&2; exit 2; }
            GROUP="$1"
            ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
    shift
done

case "$GROUP" in runtime|project|reference|all) ;; *)
    printf 'unknown project group: %s\n' "$GROUP" >&2
    exit 2
esac

mkdir -p -- "$TARGET_HOME"
failed=0
normalize_url() {
    local value="$1"
    value="${value%.git}"
    if [[ "$value" == git@github.com:* ]]; then
        value="https://github.com/${value#git@github.com:}"
    fi
    printf '%s\n' "$value"
}

while IFS=$'\t' read -r name relative url revision group; do
    [[ "$GROUP" == all || "$GROUP" == "$group" ]] || continue
    destination="$TARGET_HOME/$relative"
    if [[ ! -d "$destination/.git" ]]; then
        if [[ "$MODE" == check ]]; then
            printf 'MISSING %s %s\n' "$name" "$destination"
            failed=1
            continue
        fi
        mkdir -p -- "$(dirname -- "$destination")"
        git clone --filter=blob:none --no-checkout -- "$url" "$destination"
        git -C "$destination" fetch --depth=1 origin "$revision"
        git -C "$destination" checkout --detach "$revision"
    fi

    actual="$(git -C "$destination" rev-parse HEAD 2>/dev/null || true)"
    if [[ "$actual" != "$revision" ]]; then
        printf 'DRIFT %s expected=%s actual=%s\n' "$name" "$revision" "${actual:-none}"
        failed=1
        continue
    fi
    actual_url="$(git -C "$destination" remote get-url origin 2>/dev/null || true)"
    if [[ "$(normalize_url "$actual_url")" != "$(normalize_url "$url")" ]]; then
        printf 'REMOTE %s expected=%s actual=%s\n' "$name" "$url" "${actual_url:-none}"
        failed=1
        continue
    fi
    if [[ -n "$(git -C "$destination" status --porcelain)" ]]; then
        printf 'DIRTY %s %s\n' "$name" "$destination"
        failed=1
        continue
    fi
    printf 'OK %s %s\n' "$name" "$revision"
done < <(python3 - "$LOCK" <<'PY'
import json
import sys
from pathlib import PurePosixPath

with open(sys.argv[1], encoding="utf-8") as handle:
    value = json.load(handle)
if value.get("schema") != 1:
    raise SystemExit("unsupported project lock schema")
for project in value["projects"]:
    fields = ("name", "path", "url", "revision", "group")
    row = [project[field] for field in fields]
    if any("\t" in item or "\n" in item for item in row):
        raise SystemExit("tabs and newlines are forbidden in project fields")
    path = PurePosixPath(project["path"])
    if path.is_absolute() or ".." in path.parts:
        raise SystemExit(f"unsafe project path: {path}")
    print("\t".join(row))
PY
)

exit "$failed"
