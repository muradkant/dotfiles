# shellcheck shell=sh
# Login/session environment. Keep distribution tools authoritative; append
# Homebrew so Brew-only commands remain available without shadowing /usr/bin.
path_prepend_once() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1${PATH:+:$PATH}" ;;
    esac
}

path_append_once() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="${PATH:+$PATH:}$1" ;;
    esac
}

# Remove managed entries first so an inherited Homebrew-first or duplicated
# PATH is repaired rather than merely left in place.
path_remove_all() {
    path_remove_target="$1"
    path_remove_old="$PATH"
    # shellcheck disable=SC2123
    PATH=""
    path_remove_ifs="$IFS"
    IFS=:
    for path_remove_entry in $path_remove_old; do
        if [ -z "$path_remove_entry" ] || [ "$path_remove_entry" = "$path_remove_target" ]; then
            continue
        fi
        case ":$PATH:" in
            *":$path_remove_entry:"*) ;;
            *) PATH="${PATH:+$PATH:}$path_remove_entry" ;;
        esac
    done
    IFS="$path_remove_ifs"
    unset path_remove_target path_remove_old path_remove_ifs path_remove_entry
}

path_remove_all "$HOME/.local/bin"
path_remove_all "$HOME/.cargo/bin"
path_remove_all /home/linuxbrew/.linuxbrew/bin
path_remove_all /home/linuxbrew/.linuxbrew/sbin
path_prepend_once "$HOME/.cargo/bin"
path_prepend_once "$HOME/.local/bin"

if [ -d /home/linuxbrew/.linuxbrew ]; then
    HOMEBREW_PREFIX=/home/linuxbrew/.linuxbrew
    HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
    HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX/Homebrew"
    export HOMEBREW_PREFIX HOMEBREW_CELLAR HOMEBREW_REPOSITORY
    path_append_once "$HOMEBREW_PREFIX/bin"
    path_append_once "$HOMEBREW_PREFIX/sbin"
    case ":${MANPATH:-}:" in
        *":$HOMEBREW_PREFIX/share/man:"*) ;;
        *) MANPATH="$HOMEBREW_PREFIX/share/man:${MANPATH:-}" ;;
    esac
    case ":${INFOPATH:-}:" in
        *":$HOMEBREW_PREFIX/share/info:"*) ;;
        *) INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}" ;;
    esac
    export MANPATH INFOPATH
fi

export PATH
unset -f path_prepend_once path_append_once path_remove_all
