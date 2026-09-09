# Emacs/nvim as versioned store text. Packages stay pacman (emacs/neovim).
{
  xdg.configFile = {
    "nvim/init.lua".source = ../files/nvim/init.lua;
    "nvim/lua/plugins.lua".source = ../files/nvim/lua/plugins.lua;
    "nvim/nvim-pack-lock.json".source = ../files/nvim/nvim-pack-lock.json;
  };
  home.file = {
    ".emacs.d/init.el".source = ../files/emacs/init.el;
    ".emacs.d/early-init.el".source = ../files/emacs/early-init.el;
    ".emacs.d/lisp/fasm-mode.el".source = ../files/emacs/lisp/fasm-mode.el;
    ".emacs.d/lisp/scratch-magic-polish.el".source = ../files/emacs/lisp/scratch-magic-polish.el;
  };
}
