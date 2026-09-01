source /usr/share/cachyos-fish-config/cachyos-config.fish

eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)

# Override CachyOS's fastfetch greeting with an intentionally empty one.
function fish_greeting
end

set --export PNPM_HOME "$HOME/.local/share/pnpm/bin"
fish_add_path "$HOME/.local/bin" "$PNPM_HOME"
