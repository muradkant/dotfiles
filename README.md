# CachyOS dotfiles

The desktop I use: Hyprland, Waybar, Wofi, Kitty, Neovim, Emacs, Zellij, and a
portable set of Pi/OpenCode/Codex agent profiles.

## Desktop installation

Clone without mixing repository metadata into the home directory:

```sh
git clone --branch CachyOS https://github.com/muradkant/dotfiles.git /tmp/dotfiles
```

Back up any live configuration you intend to replace, then install:

```sh
cp /tmp/dotfiles/.bashrc ~/.bashrc
mkdir -p ~/.config ~/.emacs.d ~/.local/bin ~/Pictures
cp -a /tmp/dotfiles/hypr ~/.config/hypr
cp -a /tmp/dotfiles/kitty ~/.config/kitty
cp -a /tmp/dotfiles/nvim ~/.config/nvim
cp -a /tmp/dotfiles/waybar ~/.config/waybar
cp -a /tmp/dotfiles/wofi ~/.config/wofi
cp -a /tmp/dotfiles/wlogout ~/.config/wlogout
cp -a /tmp/dotfiles/zellij ~/.config/zellij
cp -a /tmp/dotfiles/emacs/. ~/.emacs.d/
cp -a /tmp/dotfiles/bin/. ~/.local/bin/
cp /tmp/dotfiles/background.jpg ~/Pictures/background.jpg
cp /tmp/dotfiles/lockscreen.jpg ~/Pictures/lockscreen.jpg
hyprctl reload
```

The copy is intentionally explicit: this repository reflects one machine and
does not pretend that replacing another desktop wholesale is safe.

## Agent profiles

Pi's installer is separate because it pins packages, generates derived files,
and preserves unmanaged credentials and sessions:

```sh
/tmp/dotfiles/pi/install.sh --with-opencode --with-codex
```

See [`pi/README.md`](pi/README.md) for prerequisites, profile behavior,
credentials, synchronization, and disposable verification.

## Desktop character

- Laptop workspaces 1–5 and HDMI workspaces 6–10 support mirror and extended
  modes; `hypr/reload-hdmi-extended` repairs the live transition.
- `bin/cliphist-picker` combines Cliphist, wl-clipboard, Wofi, and ImageMagick
  into searchable text and image history with cached thumbnails.
- Hyprland ecosystem tools, Waybar, Wofi, and logout UI share one square,
  i3-influenced visual language.
- Only occupied or active workspace buttons appear.
- `pi/` is portable and secret-free; generated runtime state is not tracked.
