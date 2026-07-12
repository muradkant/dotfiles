#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/backups/$(date +%Y%m%d-%H%M%S)"
INSTALL_PACKAGES=0
INSTALL_STREAMING=0
INSTALL_CONTROLLER=0
INSTALL_AGENTS=0

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Install the portable user configuration using repository-backed symlinks.
Existing destinations are moved to a timestamped backup first.

  --packages     install the desktop package manifest with pacman
  --streaming    install/link yt-stream-workspace and its package manifest
  --controller   install the controller desktop mapper (not the DKMS driver)
  --agents       install the Pi/OpenCode/Codex profiles (Pi prerequisite required)
  --full         equivalent to --packages --streaming --controller --agents
  --help         show this help

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
        --agents) INSTALL_AGENTS=1 ;;
        --full)
            INSTALL_PACKAGES=1
            INSTALL_STREAMING=1
            INSTALL_CONTROLLER=1
            INSTALL_AGENTS=1
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
    local -a packages=()
    mapfile -t packages < <(read_manifest "$manifest")
    ((${#packages[@]})) || return 0
    if [[ "${DOTFILES_SKIP_PACKAGE_INSTALL:-0}" == 1 ]]; then
        note "skipped package installation for ${manifest#"$ROOT"/}"
        return 0
    fi
    command -v pacman >/dev/null 2>&1 || die "package installation requires pacman"
    sudo pacman -S --needed "${packages[@]}"
}

git -C "$ROOT" submodule update --init --recursive

if ((INSTALL_PACKAGES)); then
    install_pacman_manifest "$ROOT/packages/desktop.txt"
fi

# Shell/login layers.
link_path "$ROOT/.bashrc" "$HOME/.bashrc"
link_path "$ROOT/.bash_profile" "$HOME/.bash_profile"
link_path "$ROOT/.profile" "$HOME/.profile"

# Desktop configuration: individual links leave room for component-owned files.
while IFS='|' read -r source destination; do
    link_path "$ROOT/$source" "$HOME/$destination"
done <<'EOF'
hypr/hyprland.conf|.config/hypr/hyprland.conf
hypr/hyprlauncher.conf|.config/hypr/hyprlauncher.conf
hypr/hyprlock.conf|.config/hypr/hyprlock.conf
hypr/hypridle.conf|.config/hypr/hypridle.conf
hypr/hyprtoolkit.conf|.config/hypr/hyprtoolkit.conf
hypr/reload-hdmi-extended|.config/hypr/reload-hdmi-extended
hypr/workspaces-hdmi-extended.conf|.config/hypr/workspaces-hdmi-extended.conf
kitty/kitty.conf|.config/kitty/kitty.conf
waybar/config.jsonc|.config/waybar/config.jsonc
waybar/style.css|.config/waybar/style.css
wofi/clipboard.conf|.config/wofi/clipboard.conf
wofi/clipboard.css|.config/wofi/clipboard.css
wlogout/layout|.config/wlogout/layout
wlogout/style.css|.config/wlogout/style.css
zellij/config.kdl|.config/zellij/config.kdl
mako/config|.config/mako/config
nvim/init.lua|.config/nvim/init.lua
nvim/lua/plugins.lua|.config/nvim/lua/plugins.lua
nvim/nvim-pack-lock.json|.config/nvim/nvim-pack-lock.json
EOF

link_path "$ROOT/background.jpg" "$HOME/Pictures/background.jpg"
link_path "$ROOT/lockscreen.jpg" "$HOME/Pictures/lockscreen.jpg"

# Emacs configuration and locally maintained integration.
link_path "$ROOT/emacs/init.el" "$HOME/.emacs.d/init.el"
link_path "$ROOT/emacs/early-init.el" "$HOME/.emacs.d/early-init.el"
for source in "$ROOT"/emacs/lisp/*.el; do
    link_path "$source" "$HOME/.emacs.d/lisp/${source##*/}"
done
link_path "$ROOT/components/emacs-opencode" \
    "$HOME/.emacs.d/site-lisp/emacs-opencode"

# User-facing helpers owned by this repository.
for source in "$ROOT"/bin/*; do
    link_path "$source" "$HOME/.local/bin/${source##*/}"
done

# Build the compatibility client only while the packaged CLI lacks --close.
[[ -x /usr/bin/hyprlauncher ]] ||
    die "hyprlauncher is missing; install packages first with --packages"
if ! /usr/bin/hyprlauncher --help 2>&1 | grep -q -- '--close'; then
    close_client="$HOME/.local/libexec/hyprlauncher-ipc"
    if [[ ! -x "$close_client" ]] ||
        ! "$close_client" --help 2>&1 | grep -q -- '--close'; then
        "$ROOT/hyprlauncher-ipc/build.sh" "$close_client"
    fi
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

if ((INSTALL_AGENTS)); then
    "$ROOT/pi/install.sh" --with-opencode --with-codex
fi

# Make the corrected login PATH available to newly started user services now;
# the next login establishes it naturally for the whole session.
# shellcheck disable=SC1091
. "$ROOT/.profile"
if [[ "${DOTFILES_SKIP_SESSION_IMPORT:-0}" != 1 ]]; then
    systemctl --user import-environment PATH 2>/dev/null || true
fi

if [[ -d "$BACKUP_ROOT" ]]; then
    note "backups: $BACKUP_ROOT"
fi
note "installation complete; run ./verify.sh"
