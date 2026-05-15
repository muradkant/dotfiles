;;; init.el --- Emacs Configuration
;;; Commentary:
;; Converted from NixOS configuration for CachyOS/Arch Linux

;;; Code:

;; ============================================================================
;; PACKAGE MANAGEMENT SETUP
;; ============================================================================

;; Set up package repositories
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("gnu" . "https://elpa.gnu.org/packages/")))
(package-initialize)

;; Bootstrap use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

;; ============================================================================
;; BASIC UI SETTINGS
;; ============================================================================

;; Load required packages early to avoid free variable warnings
(require 'display-line-numbers)
(require 'dired)

;; Basic UI settings
(setq ring-bell-function 'ignore
      evil-insert-state-cursor 'box
      initial-buffer-choice t
      display-line-numbers-type 'relative)

(setq dired-dwim-target t)
(winner-mode 1)
(menu-bar-mode 0)
(tool-bar-mode 0)
(scroll-bar-mode 0)
(column-number-mode 1)
(fringe-mode 0)
(global-display-line-numbers-mode)
(set-face-attribute 'default nil :height 170)

;; IDO mode
(ido-mode 1)
(ido-everywhere 1)

;; Backup settings
(setq-default make-backup-files nil
              auto-save-default nil
              compile-command "")

(setq undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo-tree-history/")))

;; ============================================================================
;; COMPILATION SETTINGS
;; ============================================================================

;; Compilation functions
(defun my-compile-without-history ()
  "Run compile command with an empty initial prompt but preserve history."
  (interactive)
  (let ((current-prefix-arg '(4))
        (compilation-read-command t))
    (setq-default compile-command "")
    (setq compile-command "")
    (call-interactively 'compile)
    (with-current-buffer "*compilation*"
      (evil-normal-state))))

(defun my-recompile ()
  "Recompile and ensure normal mode in compilation buffer."
  (interactive)
  (recompile)
  (with-current-buffer "*compilation*"
    (evil-normal-state)))

(advice-add 'recompile :after
            (lambda (&rest _)
              (with-current-buffer "*compilation*"
                (evil-normal-state))))

(advice-add 'compile :around
            (lambda (orig-fun &rest args)
              (let ((compile-command ""))
                (apply orig-fun args))))

(global-set-key [remap compile] 'my-compile-without-history)

;; Compilation window settings
(setq display-buffer-alist
      `((,(rx bos "*compilation*" eos)
         (display-buffer-reuse-window display-buffer-at-bottom)
         (window-height . 0.4)
         (preserve-size . (nil . t))
         (select . t))))

(setq compilation-finish-functions
      (list (lambda (_buf _str)
              (let ((win (get-buffer-window "*compilation*")))
                (when win
                  (select-window win)
                  (evil-normal-state))))))

;; ============================================================================
;; BUFFER AND FILE UTILITIES
;; ============================================================================

;; Buffer cleanup functions
(defun my/cleanup-deleted-file-buffers ()
  "Close buffers of files that no longer exist."
  (dolist (buf (buffer-list))
    (let ((filename (buffer-file-name buf)))
      (when (and filename
                 (not (file-exists-p filename)))
        (kill-buffer buf)))))

;; Dired create-file helper
(defun my/dired-create-file (filename)
  "Create a new file in the current dired directory."
  (interactive
   (list (read-string "Create file: " (dired-current-directory))))
  (let* ((filepath (expand-file-name filename (dired-current-directory)))
         (dir (file-name-directory filepath)))
    (when (and (not (file-exists-p dir))
               (yes-or-no-p (format "Directory %s does not exist. Create it? " dir)))
      (make-directory dir t))
    (when (file-exists-p dir)
      (write-region "" nil filepath)
      (dired-add-file filepath)
      (revert-buffer)
      (dired-goto-file (expand-file-name filepath)))))

;; ============================================================================
;; PACKAGE CONFIGURATIONS
;; ============================================================================

;; Evil Mode
(use-package evil
  :ensure t
  :init
  ;; Must be set *before* Evil loads
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-C-i-jump t
        evil-undo-system 'undo-tree)
  :config
  ;; Actually enable Evil
  (evil-mode 1)

  ;; Make delete operations use the black hole register
  (evil-define-operator evil-delete-blackhole (beg end type register yank-handler)
    "Delete text from BEG to END using black hole register."
    (interactive "<R><x><y>")
    (evil-delete beg end type ?_ yank-handler))

  ;; Remap d to use black hole register
  (define-key evil-normal-state-map "d" 'evil-delete-blackhole)
  (define-key evil-visual-state-map "d" 'evil-delete-blackhole)

  ;; Evil ex commands
  (evil-ex-define-cmd "Man" 'man)
  (evil-set-initial-state 'Man-mode 'normal)
  (evil-ex-define-cmd "compile" 'my-compile-without-history)
  (evil-ex-define-cmd "recompile" 'my-recompile)

  ;; Evil key bindings
  (evil-define-key '(normal insert) 'global (kbd "C-v") 'evil-paste-after)
  (evil-define-key '(normal insert) 'global (kbd "C-S-v") 'evil-paste-after)
  (evil-define-key 'normal dired-mode-map (kbd "RET") 'dired-find-file)

  (with-eval-after-load 'dired
  (evil-set-initial-state 'dired-mode 'emacs)  ; This will use Emacs default keybindings
  (define-key dired-mode-map (kbd "%") 'my/dired-create-file)
  (define-key dired-mode-map ":"
    (lambda ()
      (interactive)
      (evil-ex)))
  (define-key dired-mode-map "/" 'evil-search-forward)))

;; Undo-tree
(use-package undo-tree
  :ensure t
  :config
  (global-undo-tree-mode))

;; Direnv
(use-package direnv
  :ensure t
  :config
  (direnv-mode))

;; Gruber-darker theme
(use-package gruber-darker-theme
  :ensure t
  :config
  (load-theme 'gruber-darker t))

;; Zig mode
(use-package zig-mode
  :ensure t
  :mode ("\\.zig\\'" . zig-mode))

;; Nix mode
(use-package nix-mode
  :ensure t
  :mode ("\\.nix\\'" . nix-mode))

;; Rust mode
(use-package rust-mode
  :ensure t
  :mode ("\\.rs\\'" . rust-mode))

;; Python mode
(use-package python-mode
  :ensure t
  :mode ("\\.py\\'" . python-mode))

;; C# mode
(use-package csharp-mode
  :ensure t
  :mode ("\\.cs\\'" . csharp-mode))

;; Go mode
(use-package go-mode
  :ensure t
  :mode ("\\.go\\'" . go-mode)
  :config
  ;; Set up gofmt on save
  (add-hook 'before-save-hook 'gofmt-before-save)

  ;; Set tab width for Go files
  (add-hook 'go-mode-hook
            (lambda ()
              (setq tab-width 4)
              (setq indent-tabs-mode t))))

;; VTerm
(use-package vterm
  :ensure t
  :config
  ;; Prevent blesh and zellij from auto-starting in vterm
  (setq vterm-environment '("BLESH_AUTO_DISABLE=1"
                            "ZELLIJ=skip"
                            "INSIDE_EMACS=vterm"))

  ;; Custom vterm function
  (defun my/vterm ()
    "Open vterm with specific environment variables set."
    (interactive)
    (let ((vterm-shell (getenv "SHELL")))
      (vterm))))

(global-set-key (kbd "C-c t") 'my/vterm)

;; Magit
(use-package magit
  :ensure t)

;; ============================================================================
;; ASSEMBLY LANGUAGE MODES
;; ============================================================================

;; FASM Mode configuration
;; Add the directory containing fasm-mode.el to load-path
(add-to-list 'load-path "~/.emacs.d/lisp/")

;; Load fasm-mode only if the file exists
(if (file-exists-p "~/.emacs.d/lisp/fasm-mode.el")
    (progn
      (require 'fasm-mode)
      ;; Associate .fasm files with fasm-mode
      (add-to-list 'auto-mode-alist '("\\.fasm\\'" . fasm-mode))
      ;; Setup whitespace handling for fasm-mode
      (add-hook 'fasm-mode-hook
                (lambda ()
                  ;; Enable whitespace mode
                  (whitespace-mode 1)
                  ;; Delete trailing whitespace on save
                  (add-to-list 'write-file-functions 'delete-trailing-whitespace))))
  (message "Warning: fasm-mode.el not found"))

;; NASM Mode configuration
(use-package nasm-mode
  :ensure t
  :mode ("\\.nasm\\'" . nasm-mode)
  :config
  (add-hook 'nasm-mode-hook
            (lambda ()
              ;; Enable whitespace mode
              (whitespace-mode 1)
              ;; Delete trailing whitespace on save
              (add-to-list 'write-file-functions 'delete-trailing-whitespace))))

;; Function to switch between ASM modes based on content
(defun my/detect-asm-mode ()
  "Detect whether to use FASM or NASM mode based on file content."
  (interactive)
  (when (string-match "\\.asm\\'" (buffer-file-name))
    ;; Check for NASM-specific format indicators in the first few lines
    (save-excursion
      (goto-char (point-min))
      (if (re-search-forward "\\(section\\|segment\\|global\\|extern\\)\\s-+[._a-zA-Z0-9]+" nil t)
          (nasm-mode)
        (fasm-mode)))))

;; Associate .asm files with the detector function
(add-to-list 'auto-mode-alist '("\\.asm\\'" . my/detect-asm-mode))

;; Commands to explicitly switch between modes
(defun my/switch-to-fasm-mode ()
  "Switch current buffer to FASM mode."
  (interactive)
  (fasm-mode)
  (message "Switched to FASM mode"))

(defun my/switch-to-nasm-mode ()
  "Switch current buffer to NASM mode."
  (interactive)
  (nasm-mode)
  (message "Switched to NASM mode"))

(defun my/show-current-mode ()
  "Display the current major mode."
  (interactive)
  (message "Current mode: %s" major-mode))

;; Add key bindings for switching between modes
(global-set-key (kbd "C-c f") 'my/switch-to-fasm-mode)
(global-set-key (kbd "C-c n") 'my/switch-to-nasm-mode)

(global-set-key (kbd "C-c m") 'my/show-current-mode)

;; ============================================================================
;; SCRATCH MAGIC POLISH
;; ============================================================================

;; Preferred API key setup:
;; - Shell env var: GEMINI_API_KEY
;; - Or put this in ~/.emacs.d/local-secrets.el (untracked):
;;   (setq scratch-magic-api-key "YOUR_GEMINI_API_KEY")
(let ((my/local-secrets-file (expand-file-name "local-secrets.el" user-emacs-directory)))
  (when (file-readable-p my/local-secrets-file)
    (load my/local-secrets-file nil t)))

;; Optional model override (default is already gemini-3-flash-preview):
;; (setq scratch-magic-model "gemini-3-flash-preview")

(when (require 'scratch-magic-polish nil t)
  ;; Local-only binding in *scratch* so existing global mappings remain intact.
  (defun my/scratch-magic-bind-key ()
    "Bind C-c m to scratch magic only in *scratch*."
    (when (and (derived-mode-p 'lisp-interaction-mode)
               (string= (buffer-name) "*scratch*"))
      (local-set-key (kbd "C-c m") #'scratch-magic-polish)))
  (add-hook 'lisp-interaction-mode-hook #'my/scratch-magic-bind-key)
  ;; Apply immediately when reloading config with an already-open *scratch*.
  (when (get-buffer "*scratch*")
    (with-current-buffer "*scratch*"
      (my/scratch-magic-bind-key))))

;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
