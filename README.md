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

mkdir -p ~/.config ~/.emacs.d ~/Pictures
cp -a /tmp/dotfiles/hypr ~/.config/hypr
cp -a /tmp/dotfiles/kitty ~/.config/kitty
cp -a /tmp/dotfiles/nvim ~/.config/nvim
cp -a /tmp/dotfiles/waybar ~/.config/waybar
cp -a /tmp/dotfiles/wlogout ~/.config/wlogout
cp -a /tmp/dotfiles/zellij ~/.config/zellij
cp -a /tmp/dotfiles/emacs/. ~/.emacs.d/
cp /tmp/dotfiles/background.jpg ~/Pictures/background.jpg
cp /tmp/dotfiles/lockscreen.jpg ~/Pictures/lockscreen.jpg
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
- Empty workspace buttons are not forced; only active workspaces should appear.
