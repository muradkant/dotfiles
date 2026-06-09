#
# ~/.bashrc
#

# Shared PATH setup for interactive and non-interactive Bash shells.
export PATH="$HOME/.local/bin:$PATH"
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
fi

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
export EDITOR=nvim
eval "$(starship init bash)"

# strix
[[ -d "$HOME/.strix/bin" ]] && export PATH="$HOME/.strix/bin:$PATH"
