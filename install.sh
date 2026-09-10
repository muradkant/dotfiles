#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/backups/$(date +%Y%m%d-%H%M%S)"
INSTALL_PACKAGES=0
INSTALL_STREAMING=0
INSTALL_CONTROLLER=0
INSTALL_SERVICES=0
INSTALL_PROJECTS=0

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Apply the Home Manager configuration (flake at the repository root),
which owns all shell/desktop/editor dotfiles. Provisioning flags add
the parts Home Manager deliberately does not own (pacman binaries and
drivers stay with CachyOS/Arch for GPU compatibility).

  --packages     install the desktop package manifest with pacman
  --streaming    install/link yt-stream-workspace and its package manifest
  --controller   install the controller desktop mapper (not the DKMS driver)
  --services     install local search and speech service definitions
  --projects     clone missing standalone repositories at locked revisions
  --full         switch Home Manager and enable every optional component
  --help         show this help

Set DOTFILES_SKIP_HM=1 to skip the Home Manager switch (used by tests
that run against a disposable HOME without nix).

The hardware driver remains an explicit, separately verified operation in
components/linux-zhixu-controller-fix. Credentials and personal data are never
copied by this installer.
EOF
}

while (($#)); do
    case "$1" in
        --packages) INSTALL_PACKAGES=1 ;;
        --streaming) INSTALL_STREAMING=1 ;;
        --controller) INSTALL_CONTROLLER=1 ;;
        --services) INSTALL_SERVICES=1 ;;
        --projects) INSTALL_PROJECTS=1 ;;
        --full)
            INSTALL_PACKAGES=1
            INSTALL_STREAMING=1
            INSTALL_CONTROLLER=1
            INSTALL_SERVICES=1
            INSTALL_PROJECTS=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'install.sh: unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

note() {
    printf 'dotfiles: %s\n' "$*"
}

die() {
    note "$*" >&2
    exit 1
}

backup_destination() {
    local destination="$1" relative backup

    [[ -e "$destination" || -L "$destination" ]] || return 0
    relative="${destination#"$HOME"/}"
    backup="$BACKUP_ROOT/$relative"
    mkdir -p -- "$(dirname -- "$backup")"
    mv -- "$destination" "$backup"
    note "backed up ~/$relative"
}

link_path() {
    local source="$1" destination="$2"
    local current_source=""

    [[ -e "$source" || -L "$source" ]] || die "missing repository source: $source"
    if [[ -L "$destination" ]]; then
        current_source="$(readlink -f -- "$destination" 2>/dev/null || true)"
        if [[ "$current_source" == "$(readlink -f -- "$source")" ]]; then
            return 0
        fi
    fi

    backup_destination "$destination"
    mkdir -p -- "$(dirname -- "$destination")"
    ln -s -- "$source" "$destination"
    note "linked ${destination#"$HOME"/}"
}

install_template() {
    local source="$1" destination="$2"

    [[ -e "$source" ]] || die "missing repository template: $source"
    if [[ -e "$destination" || -L "$destination" ]]; then
        note "preserved ${destination#"$HOME"/}"
        return 0
    fi
    mkdir -p -- "$(dirname -- "$destination")"
    install -m 0600 -- "$source" "$destination"
    note "created ${destination#"$HOME"/} from template"
}

read_manifest() {
    sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$1"
}

install_pacman_manifest() {
    local manifest="$1"
    local -a packages=() missing=()
    mapfile -t packages < <(read_manifest "$manifest")
    ((${#packages[@]})) || return 0
    if [[ "${DOTFILES_SKIP_PACKAGE_INSTALL:-0}" == 1 ]]; then
        note "skipped package installation for ${manifest#"$ROOT"/}"
        return 0
    fi
    command -v pacman >/dev/null 2>&1 || die "package installation requires pacman"
    mapfile -t missing < <(pacman -T "${packages[@]}" 2>/dev/null || true)
    if ((${#missing[@]} == 0)); then
        note "packages already satisfied: ${manifest#"$ROOT"/}"
        return 0
    fi
    sudo pacman -S --needed "${missing[@]}"
}

git -C "$ROOT" submodule update --init --recursive
if ((INSTALL_PROJECTS)); then
    "$ROOT/projects/sync.sh" --materialize --group all
fi

if ((INSTALL_PACKAGES)); then
    install_pacman_manifest "$ROOT/packages/desktop.txt"
fi

# Shell, desktop, and editor configuration is owned by Home Manager now
# (flake at the repository root). This replaces the old repository-symlink
# farm; content lives in files/ and modules/, deployed with -b backups.
# Nix lives outside the default PATH in non-login shells, so ensure its
# profile bins are visible before probing (appended: never shadow system).
for nix_bin in "$HOME/.nix-profile/bin" /nix/var/nix/profiles/default/bin; do
    case ":${PATH}:" in
        *:"$nix_bin":*) ;;
        *) PATH="$PATH:$nix_bin" ;;
    esac
done
export PATH
if [[ "${DOTFILES_SKIP_HM:-0}" == 1 ]]; then
    note "skipped home-manager switch (DOTFILES_SKIP_HM=1)"
elif command -v home-manager >/dev/null 2>&1; then
    home-manager switch --flake "$ROOT"
elif command -v nix >/dev/null 2>&1; then
    nix run home-manager/master -- switch --flake "$ROOT"
else
    die "home-manager switch requires nix: install nix, then rerun"
fi

if ((INSTALL_STREAMING)); then
    install_pacman_manifest "$ROOT/packages/streaming.txt"
    link_path "$ROOT/components/yt-stream-workspace/bin/workspace-stream" \
        "$HOME/.local/bin/workspace-stream"
    install_template "$ROOT/components/yt-stream-workspace/config.example" \
        "$HOME/.config/yt-stream-workspace/config"
fi

if ((INSTALL_CONTROLLER)); then
    controller="$ROOT/components/linux-zhixu-controller-fix"
    install_pacman_manifest "$ROOT/packages/controller.txt"
    link_path "$controller/antimicrox/desktop.gamecontroller.amgp" \
        "$HOME/.config/antimicrox/desktop.gamecontroller.amgp"
    link_path "$controller/scripts/controller-mouse-game-guard" \
        "$HOME/.local/bin/controller-mouse-game-guard"
    link_path "$controller/scripts/controller-mouse-toggle.sh" \
        "$HOME/.local/bin/controller-mouse-toggle"
    link_path "$controller/scripts/game-with-controller.sh" \
        "$HOME/.local/bin/game-with-controller"
    link_path "$controller/systemd/controller-mouse.service" \
        "$HOME/.config/systemd/user/controller-mouse.service"
    link_path "$controller/systemd/controller-mouse-game-guard.service" \
        "$HOME/.config/systemd/user/controller-mouse-game-guard.service"
    if [[ "${DOTFILES_SKIP_USER_SERVICES:-0}" != 1 ]]; then
        systemctl --user daemon-reload
        systemctl --user enable --now \
            controller-mouse.service controller-mouse-game-guard.service
    fi
fi

if ((INSTALL_SERVICES)); then
    install_pacman_manifest "$ROOT/packages/services.txt"
    "$ROOT/services/searxng/install.sh"
    if [[ "${DOTFILES_SKIP_SERVICE_BUILDS:-0}" != 1 ]]; then
        "$ROOT/services/kokoro/install.sh"
    fi

    link_path "$ROOT/services/kokoro/server.py" \
        "$HOME/.local/libexec/kokoro-tts-server.py"
    link_path "$ROOT/services/searxng/searxng.container" \
        "$HOME/.config/containers/systemd/searxng.container"
    for source in "$ROOT"/systemd/user/*.service; do
        link_path "$source" "$HOME/.config/systemd/user/${source##*/}"
    done
    if [[ "${DOTFILES_SKIP_USER_SERVICES:-0}" != 1 ]]; then
        systemctl --user daemon-reload
        systemctl --user enable --now kokoro-tts.service searxng.service
    fi
fi

# Make the Home Manager login environment available to newly started user
# services now; the next login establishes it naturally for the session.
# The generated script is not `set -u` clean, so relax nounset around it.
if [[ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]]; then
    set +u
    # shellcheck disable=SC1091
    . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    set -u
fi
if [[ "${DOTFILES_SKIP_SESSION_IMPORT:-0}" != 1 ]]; then
    systemctl --user import-environment PATH 2>/dev/null || true
fi

if [[ -d "$BACKUP_ROOT" ]]; then
    note "backups: $BACKUP_ROOT"
fi
note "installation complete; run ./verify.sh"
