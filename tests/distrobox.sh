#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BOX_NAME="${DOTFILES_TEST_BOX:-dotfiles-test-$UID-$$}"
BOX_IMAGE="${DOTFILES_TEST_IMAGE:-docker.io/library/archlinux:latest}"
BOX_HOME="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-distrobox.XXXXXX")"

cleanup() {
    distrobox rm --force "$BOX_NAME" >/dev/null 2>&1 || true
    find "$BOX_HOME" -depth -delete 2>/dev/null || true
}
trap cleanup EXIT

command -v distrobox >/dev/null 2>&1 || {
    printf '%s\n' 'distrobox is required' >&2
    exit 1
}
command -v podman >/dev/null 2>&1 || {
    printf '%s\n' 'podman is required' >&2
    exit 1
}

if distrobox list 2>/dev/null | awk 'NR > 1 {print $3}' |
    grep -Fxq "$BOX_NAME"; then
    printf 'Distrobox already exists: %s\n' "$BOX_NAME" >&2
    exit 1
fi

distrobox create --yes \
    --name "$BOX_NAME" \
    --image "$BOX_IMAGE" \
    --home "$BOX_HOME" \
    --volume "$ROOT:/opt/dotfiles:ro"

# This program is expanded inside the container, not by the host shell.
# shellcheck disable=SC2016
distrobox enter "$BOX_NAME" -- bash -lc '
    set -Eeuo pipefail
    sudo pacman -Syu --needed --noconfirm \
        git nodejs openssl pnpm power-profiles-daemon python python-gobject uv
    cp -a /opt/dotfiles "$HOME/dotfiles"
    cd "$HOME/dotfiles"
    ./tests/bash-startup.sh
    ./tests/install-smoke.sh
    ./tests/projects-sync.sh

    for forbidden in npm npx bun yarn corepack pip pip3 pipx poetry pdm hatch rye conda mamba; do
        if command -v "$forbidden" >/dev/null 2>&1; then
            printf "forbidden package manager available in clean image: %s\n" \
                "$forbidden" >&2
            exit 1
        fi
    done
'

printf '%s\n' 'PASS disposable Arch Distrobox workstation restore'
