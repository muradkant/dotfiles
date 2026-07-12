# shellcheck shell=bash disable=SC1091
[[ -r "$HOME/.profile" ]] && . "$HOME/.profile"
[[ $- == *i* && -r "$HOME/.bashrc" ]] && . "$HOME/.bashrc"
