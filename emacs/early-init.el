;;; early-init.el --- Early Initialization
;;; Commentary:
;; This file is loaded before init.el and package initialization

;;; Code:

;; Disable package.el initialization so use-package can control it
(setq package-enable-at-startup nil)

;; Pre-load Evil settings
(setq evil-want-integration t
      evil-want-keybinding nil
      evil-want-C-u-scroll t
      evil-want-C-i-jump t
      evil-undo-system 'undo-tree)

;;; early-init.el ends here
