#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-projects.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

git init --quiet "$TMP/source"
git -C "$TMP/source" config user.name test
git -C "$TMP/source" config user.email test@example.invalid
printf 'pinned\n' >"$TMP/source/content"
git -C "$TMP/source" add content
git -C "$TMP/source" commit --quiet -m pinned
revision="$(git -C "$TMP/source" rev-parse HEAD)"

python3 - "$TMP/lock.json" "$TMP/source" "$revision" <<'PY'
import json
import sys

value = {
    "schema": 1,
    "projects": [{
        "name": "fixture",
        "path": "Projects/fixture",
        "url": sys.argv[2],
        "revision": sys.argv[3],
        "group": "project",
    }],
}
with open(sys.argv[1], "w", encoding="utf-8") as handle:
    json.dump(value, handle)
PY

export PROJECT_LOCK_FILE="$TMP/lock.json"
export PROJECT_TARGET_HOME="$TMP/home"
if "$ROOT/projects/sync.sh" --group project; then
    printf '%s\n' 'missing project unexpectedly passed' >&2
    exit 1
fi
"$ROOT/projects/sync.sh" --materialize --group project
"$ROOT/projects/sync.sh" --group project
printf 'local change\n' >>"$TMP/home/Projects/fixture/content"
if "$ROOT/projects/sync.sh" --materialize --group project; then
    printf '%s\n' 'dirty project unexpectedly passed' >&2
    exit 1
fi
grep -q '^local change$' "$TMP/home/Projects/fixture/content"

printf '%s\n' 'PASS project materialization, pin check, and dirty-tree preservation'
