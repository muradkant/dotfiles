# Hyprland/kitty/noctalia/swash/herdr/uwsm: config text only.
# Binaries + GPU + drivers stay with pacman/CachyOS — do NOT enable
# wayland.windowManager.hyprland here (nothing to generate; raw files win).
#
# hypr/ and kitty/ MUST stay recursive directory sources, not per-file
# entries: HM stages every per-file source as its own isolated store object,
# scattering Lua siblings across /nix/store. Hyprland canonicalizes the entry
# file (realpath) and resolves require("config.*") next to the canonical
# location, so scattered per-file links fail at (re)load. A recursive dir
# keeps one staged tree: entry and siblings share a canonical root. Same
# hazard applies to kitty's `include themes/...`.
{ config, ... }:
{
  xdg.configFile = {
    "hypr" = {
      source = ../files/hypr;
      recursive = true;
    };
    "kitty" = {
      source = ../files/kitty;
      recursive = true;
    };
    "noctalia/config.toml".source = ../files/noctalia.toml;
    "swash/settings.ini".source = ../files/swash.ini;
    "herdr/config.toml".source = ../files/herdr.toml;
    "uwsm/env".source = ../files/uwsm-env;
  };
  home.sessionVariables.BROWSER = "firefox";
}
