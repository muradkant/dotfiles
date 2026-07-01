# Dotfiles

Personal CachyOS desktop configuration.

## Install

Clone the repo somewhere temporary:

```sh
git clone -b CachyOS git@github.com:muradkant/dotfiles.git /tmp/dotfiles
```

Copy the files into their live locations:

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
```

Install the portable Pi profile separately. This installs its pinned packages,
generates presets from the tracked Markdown profiles, and leaves credentials
and sessions untouched:

```sh
/tmp/dotfiles/pi/install.sh
```

Reload Hyprland after copying:

```sh
hyprctl reload
```

## Notes

- `hypr/hyprland.conf` contains HDMI mirror and extended-monitor modes.
- Extended mode maps laptop workspaces to `1-5` and HDMI workspaces to `6-10`.
- `hypr/reload-hdmi-extended` repairs the live mirror-to-extension transition by
  republishing the HDMI output before restarting Waybar and the wallpaper.
- `bin/cliphist-picker` uses `cliphist`, `wl-clipboard`, `wofi`, and ImageMagick
  to provide searchable clipboard history with cached image thumbnails.
- `hypr/hyprtoolkit.conf` gives Hypr ecosystem applications the same palette,
  typography, and square geometry as Waybar and the Wofi clipboard picker.
- Empty workspace buttons are not forced; only active workspaces should appear.
- `pi/` is the portable, secret-free source for the global Pi profile.
