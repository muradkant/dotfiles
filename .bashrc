# shellcheck shell=bash
# Interactive Bash only. Login/session environment belongs in ~/.profile.
[[ $- == *i* ]] || return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
export EDITOR=nvim
PS1='[\u@\h \W]\$ '

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
else
    unset STARSHIP_SESSION_KEY STARSHIP_SHELL
fi

[[ -d "$HOME/.strix/bin" ]] &&
    case ":$PATH:" in
        *":$HOME/.strix/bin:"*) ;;
        *) export PATH="$HOME/.strix/bin:$PATH" ;;
    esac
