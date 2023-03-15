;; -*- lexical-binding: t; -*-

;; Emacs initialization
(setq inhibit-startup-message t 		    ; Disable the startup message
      column-number-indicator-zero-based nil        ; Column number starts at one
      native-comp-async-report-warnings-errors nil) ; Silence Compiler warnings

(tool-bar-mode -1)          ; Disable the toolbar
(tooltip-mode -1)           ; Disable tooltips
(set-fringe-mode 15)        ; Give some breathing room
(menu-bar-mode -1)          ; Disable the menu bar
(scroll-bar-mode -1)        ; Disable visible scrollbar
(display-battery-mode 1)    ; Display battery status
(column-number-mode)	    ; Display column number
(repeat-mode)		    ; Enable repeat-mode

;; Startup performance
  ;; Reducing the frequency of garbage collection
(setq gc-cons-threshold (* 2 1000 1000))

  ;; Profile emacs startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (message "*** Emacs loaded in %s with %d garbage collections."
                     (format "%.2f seconds"
                             (float-time
                              (time-subtract after-init-time before-init-time)))
                     gcs-done)))

;; Improve scrolling
(setq mouse-wheel-scroll-amount '(1 ((shift) . 1)) ; one line at a time
      mouse-wheel-progressive-speed nil 	   ; don't accelerate scrolling
      mouse-wheel-follow-mouse 't 		   ; scroll window under mouse
      scroll-step 1				   ; scroll one line at time
      scroll-margin 5)				   ; set the margin to fiv lines

;; Set frame tansparency and maximize windows by default
(set-frame-parameter (selected-frame) 'alpha '(90 . 90))
  (add-to-list 'default-frame-alist '(alpha . (90 . 90)))
(set-frame-parameter (selected-frame) 'fullscreen 'maximized)
  (add-to-list 'default-frame-alist '(fullscreen . maximized))

;; Keep transient cruft out of ~/.emacs.d/
(setq user-emacs-directory "~/.cache/emacs/"
      backup-directory-alist `(("." . ,(expand-file-name "backups" user-emacs-directory)))
      url-history-file (expand-file-name "url/history" user-emacs-directory)
      auto-save-list-file-prefix (expand-file-name "auto-save-list/.saves-" user-emacs-directory)
      native-comp-eln-load-path (list (expand-file-name "eln-cache/" user-emacs-directory)))

;; Keep customization settings in a temporary file
(setq custom-file
      (if (boundp 'server-socket-dir)
          (expand-file-name "custom.el" server-socket-dir)
        (expand-file-name (format "emacs-custom-%s.el" (user-uid)) temporary-file-directory)))
(load custom-file t)

;; Initialize package sources
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
			 ("mepla-stable" . "https://stable.melpa.org/packages/")
                         ("elpa" . "https://elpa.gnu.org/packages/")
			 ("nongnu-elpa" . "https://elpa.nongnu.org/nongnu/")))
(package-initialize)
(unless package-archive-contents
 (package-refresh-contents))

;; Emacs theme
(load-theme 'Sholum t)

;; Use-package configuration
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)
(require 'use-package-ensure)
(setq use-package-always-ensure t)

;; Set up the visible bell
(setq visible-bell t)

;; Fill-column
(setq-default fill-column 80)

;; Font
  ;; Enable proper Unicode glyph support
(defun replace-unicode-font-mapping (block-name old-font new-font)
  (let* ((block-idx (cl-position-if
                         (lambda (i) (string-equal (car i) block-name))
                         unicode-fonts-block-font-mapping))
         (block-fonts (cadr (nth block-idx unicode-fonts-block-font-mapping)))
         (updated-block (cl-substitute new-font old-font block-fonts :test 'string-equal)))
    (setf (cdr (nth block-idx unicode-fonts-block-font-mapping))
          `(,updated-block))))

;; Cursor configuration
(setq-default cursor-type 'bar)
(blink-cursor-mode 0)

;; Stop creating those #auto-save# files
(setq auto-save-default nil)

;; Disable line numbers for some modes
(require 'display-line-numbers)
(defcustom display-line-numbers-exempt-modes '(vterm-mode eshell-mode shell-mode term-mode ansi-term-mode pdf-view-mode doc-view-mode which-key-mode telega-chat-mode telega-root-mode)
  "Major modes on which to disable the linum mode, exempts them from global requirement"
  :group 'display-line-numbers
  :type 'list
  :version "green")

(defun display-line-numbers--turn-on ()
  "turn on line numbers but excempting certain majore modes defined in `display-line-numbers-exempt-modes'"
  (if (and
       (not (member major-mode display-line-numbers-exempt-modes))
       (not (minibufferp)))
      (display-line-numbers-mode)))

(global-display-line-numbers-mode)

;; EXWM configuration

  ;; Launch apps that will run in the background
  (defun run-in-background (command)
    (let ((command-parts (split-string command "[ ]+")))
      (apply #'call-process `(,(car command-parts) nil 0 nil ,@(cdr command-parts)))))

  (run-in-background "pasystray")
  (run-in-background "nm-applet")
  (run-in-background "dunst")
  (run-in-background "caffeine")
  (run-in-background "redshift -O 3800 -P -r")
  (run-in-background "kdeconnect-cli")

(defun exwm-init-hook ()
  ;; Make workspace 0 be the one where we land at startup
  (exwm-workspace-switch-create 0))

(defun exwm-update-class ()
  (exwm-workspace-rename-buffer exwm-class-name))

(defun exwm-update-title ()
  (pcase exwm-class-name
    ("Brave-browser" (exwm-workspace-rename-buffer (format "%s" exwm-title)))
    ("qutebrowser" (exwm-workspace-rename-buffer (format "%s" exwm-title)))
    ("okular" (exwm-workspace-rename-buffer (format "%s" exwm-title)))))

(use-package exwm
  :config
  ;; Set the default number of workspaces
  (setq exwm-workspace-number 5)

  ;; When window "class" updates, use it to set the buffer name
  (add-hook 'exwm-update-class-hook #'exwm-update-class)

  ;; When window title updates, use it to set the buffer name
  (add-hook 'exwm-update-title-hook #'exwm-update-title)

  ;; When EXWM starts up, do some extra configuration
  (add-hook 'exwm-init-hook #'exwm-init-hook)

  ;; Rebind ESC to CapsLock and vice versa
  (start-process-shell-command "xmodmap" nil "xmodmap ~/.emacs.d/exwm/Xmodmap")

  ;; Set the screen resolution
  (require 'exwm-randr)
  (exwm-randr-enable)
  (start-process-shell-command "xrandr" nil "xrandr --output VGA1 --primary --mode 1920x1080 --pos 0x0 --rotate normal --output VIRTUAL1 --off")

  ;; Set the wallpaper
  (defun set-wallpaper ()
    (interactive)
    (start-process-shell-command "feh" nil "feh --bg-scale ~/Downloads/.Wallpaper.jpg"))
  (set-wallpaper)

  ;; System-tray configuration
  (require 'exwm-systemtray)
  (setq exwm-systemtray-height 16)
  (exwm-systemtray-enable)

  ;; These keys should always pass through to Emacs
  (setq exwm-input-prefix-keys
	'(?\C-x
	  ?\C-u
	  ?\C-h
	  ?\C-w
	  ?\M-x
	  ?\M-`
	  ?\M-&
	  ?\M-:
	  ?\C-\M-j ;; Buffer list
	  ?\C-\ )) ;; Ctrl-Space

  ;; Ctrl-Q will enable the next key to be sent directly
  (define-key exwm-mode-map [?\C-q] 'exwm-input-send-next-key)

  ;; Set up global key bindings. These always work, no matter the input state!
  ;; Keep in mind that changing this list after EXWM initializs has no effect.
  (setq exwm-input-global-keys
	`(
	  ;; Reset to line-mode (C-c C-k switches to char-mode via exwm-input-release-keyboard)
	  ([?\s-r] . exwm-reset)

	  ;; Launch applications via shell command
	  ([?\s- ] . (lambda (command)
		       (interactive (list (read-shell-command "$ ")))
		       (start-process-shell-command command nil command)))

	  ;; Switch workspace
	  ([?\s-w] . exwm-workspace-switch)

	  ;; 's-N': Switch to certain workspace with Super plus a number key (0-9)
	  ,@(mapcar (lambda (i)
		      `(,(kbd (format "s-%d" i)) .
			(lambda()
			  (interactive)
			  (exwm-workspace-switch-create ,i))))
		    (number-sequence 0 9))))

  ;; Since 'exwm-input-set-key' does not accept lists, here is a replacement
  (defun exwm-key-input (i)
    (mapcar (lambda (arg)
              (let ((key (car arg))
                    (fun (cdr arg)))
		(exwm-input-set-key (kbd key) fun)))
	    i))
  ;; Don't let ediff break EXWM, keep it in one frame
  (setq ediff-diff-options "-w"
	ediff-split-window-function 'split-window-horizontally
	ediff-window-setup-function 'ediff-setup-windows-plain)

  ;; Enable exwm
  (exwm-enable))

;; Dashboard configuration
(use-package dashboard
  :config
  (setq dashboard-banner-logo-title "Welcome to Emacs, Sholum"
	dashboard-startup-banner 'logo
	dashboard-set-init-info t
	dashboard-center-content t
	dashboard-items '((recents . 10)
			  (agenda . 15)
			  (bookmarks . 5))))
(dashboard-setup-startup-hook)

;; Desktop Environment configuration
(use-package desktop-environment
  :after exwm
  :config
  (exwm-key-input
   '(("s-." . desktop-environment-volume-increment)
     ("s->" . desktop-environment-volume-increment-slowly)
     ("s-," . desktop-environment-volume-decrement)
     ("s-<" . desktop-environment-volume-decrement-slowly)
     ("s-m" . desktop-environment-toggle-music)
     ("s-s" . desktop-environment-screenshot)
     ("s-S" . desktop-environment-screenshot-part)))
  :custom
  (desktop-environment-brightness-small-increment "1%+")
  (desktop-environment-brightness-small-decrement "1%-")
  (desktop-environment-brightness-normal-increment "5%+")
  (desktop-environment-brightness-normal-decrement "5%-")
  (desktop-environment-volume-small-increment "1%+")
  (desktop-environment-volume-small-decrement "1%-")
  (desktop-environment-volume-normal-increment "5%+")
  (desktop-environment-volume-normal-decrement "5%-")
  :init
  (desktop-environment-mode))

;; Simplify Leader Bindings
(use-package general
  :config
  (general-evil-setup t)

  (general-create-definer leader-key-def
    :keymaps '(normal insert visual emacs)
    :prefix "SPC"
    :global-prefix "C-SPC")

  (general-create-definer ctrl-c-keys
    :prefix "C-c"))

  ;; Which-key configuration
(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 0.3
	which-key-allow-evil-operators t))

  ;; ESC cancels all
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

;; Rebind C-u (since evil take it over)
(global-set-key (kbd "C-M-u") 'universal-argument)

;; Evil Mode
(defun evil-hook ()
  (dolist (mode '(custom-mode
                  eshell-mode
                  term-mode))
    (add-to-list 'evil-emacs-state-modes mode)))

(use-package evil
  :init
  (setq evil-want-integration t
	evil-want-keybinding nil
	evil-want-C-u-scroll t
	evil-want-C-i-jump t
	evil-respect-visual-line-mode t
	evil-move-beyond-eol t)
  :config
  (add-hook 'evil-mode-hook 'evil-hook)
  (evil-mode 1)
  (define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state)
  (define-key evil-insert-state-map (kbd "C-h") 'evil-delete-backward-char-and-join)

  ;; Use visual line motions even outside of visual-line-mode buffers
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)

  (evil-set-initial-state 'messages-buffer-mode 'normal)
  (evil-set-initial-state 'dashboard-mode 'normal))

  ;; Evil collection
(use-package evil-collection
  :after evil
  :custom
  (evil-collection-outline-bind-tab-p nil)
  :config
  (evil-collection-init))

;; Undo/redo configuration
(use-package undo-tree
  :after evil
  :diminish
  :config
  (evil-set-undo-system 'undo-tree)
  (global-undo-tree-mode 1)
  (setq undo-tree-history-directory-alist `(("." . ,(expand-file-name "undo" user-emacs-directory)))))

;; Hydra
(use-package hydra
  :defer 1)

;; Completions with Vertico
(defun minibuffer-backward-kill (arg)
  "When minibuffer is completing a file name delete up to parent
folder, otherwise delete a word"
  (interactive "p")
  (if minibuffer-completing-file-name
      (if (string-match-p "/." (minibuffer-contents))
          (zap-up-to-char (- arg) ?/)
        (delete-minibuffer-contents))
    (delete-word (- arg))))

(use-package vertico
  :init (vertico-mode)
  :bind
  (:map vertico-map
	("C-j" . vertico-next)
	("C-k" . vertico-previous)
  (:map minibuffer-local-map
	("C-DEL" . minibuffer-backward-kill)))
  :custom
  (vertico-cycle t))

(use-package savehist
  :init (savehist-mode)
  :config (setq history-length 25
	        history-delete-duplicates t))

;; Consult configuration
(use-package consult
  :bind ("C-s" . consult-line))

(leader-key-def
  "c"	'(:ignore t :which-key "consult")
  "cy"	'(consult-yank-from-kill-ring :which-key "kill ring")
  "cl"	'(consult-goto-line :which-key "goto line")
  "ci"	'(consult-imenu :which-key "imenu")
  "cg"  '(consult-grep :which-key "grep")
  "cl"  '(consult-goto-line :which-key "goto line")
  "cf"  '(consult-locate :which-key "locate"))

;; Improved Candidate Filtering with Orderless
(use-package orderless
  :config
  (setq completion-styles '(orderless)
	completion-category-defaults nil
	completion-category-overrides '((file (styles . (partial-completion))))))

;; Completion Annotations with Marginalia
(use-package marginalia
  :init (marginalia-mode))

;; Embark configuration
(defun embark-sudo-edit ()
  (interactive)
  (find-file (concat "/sudo:root@localhost:"
                     (expand-file-name (read-file-name "Find file as root: ")))))

(use-package embark
  :bind
  (("C->" . embark-dwim)
   ("C-;" . embark-act)
   ("C-h B" . embark-bindings)
   :map embark-file-map
   ("s" . embark-sudo-edit))
  :init
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :after (embark consult)
  :demand t
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; Jumping with Avy
(use-package avy
  :commands (avy-goto-char avy-goto-word-0 avy-goto-line)
  :custom
  (leader-key-def
    "j"   '(:ignore t :which-key "jump")
    "jj"  '(avy-goto-char :which-key "jump to char")
    "jw"  '(avy-goto-word-0 :which-key "jump to word")
    "jl"  '(avy-goto-line :which-key "jump to line")))

;; Change theme / White space mode
(leader-key-def
  "t"  '(:ignore t :which-key "toggles")
  "tw" '(whitespace-mode :which-key "whitespace")
  "te" '(eshell-toggle :which-key "eshell"))

;; Highlight Matching Braces
(use-package paren
  :config
  (set-face-attribute 'show-paren-match-expression nil :background "#363e4a")
  (show-paren-mode 1))

;; Smart Parens
(use-package smartparens
  :hook ((prog-mode . smartparens-mode)
         (org-mode . smartparens-mode)))

;; Pinentry
(use-package pinentry
  :config
  (setq epg-pinentry-mode 'loopback))
(pinentry-start)

;; Rainbow delimiters
(use-package rainbow-delimiters
  :hook ((prog-mode . rainbow-delimiters-mode)
         (org-mode . rainbow-delimiters-mode)))

;; Rainbow mode
(use-package rainbow-mode
  :defer t
  :hook (org-mode))

;; Flycheck configuration
(use-package flycheck
  :defer t
  :hook
  (org-mode . flycheck-mode))

;; TRAMP
  ;; Set default connection mode to SSH
(setq tramp-default-method "ssh")

;; Commenting lines
(use-package evil-nerd-commenter
  :bind ("M-p" . evilnc-comment-or-uncomment-lines))

(use-package ws-butler
  :hook (((text-mode . ws-butler-mode)
         (prog-mode . ws-butler-mode)
         (org-mode . ws-butler-mode))))

;; Displaying World Time
(setq world-clock-list
  '(("America/Sao_Paulo" "Brasilia")
    ("America/Los_Angeles" "Seattle")
    ("America/New_York" "New York")
    ("Europe/Athens" "Athens")
    ("Pacific/Auckland" "Auckland")
    ("Asia/Shanghai" "Shanghai"))
    world-clock-format "%a, %d %b %H:%M %p %Z")

;; Mode Line
  ;; Basic
(setq display-time-format "%H:%M %d/%m/%y"
      displat-time-default-load-average nil
      display-time-day-and-date t)
(display-time-mode 1)

(use-package diminish)

  ;; Smart Mode Line
(use-package smart-mode-line
  :config
  (setq sml/no-confirm-load-theme t)
  (sml/setup)
  (sml/apply-theme 'respectful) ; Respect the theme colors
  (setq sml/mode-width 'right
      sml/name-width 60)

  (setq-default mode-line-format
  `("%e"
      mode-line-front-space
      evil-mode-line-tag
      mode-line-mule-info
      mode-line-client
      mode-line-modified
      mode-line-remote
      mode-line-frame-identification
      mode-line-buffer-identification
      sml/pos-id-separator
      (vc-mode vc-mode)
      " "
      ;mode-line-position
      sml/pre-modes-separator
      mode-line-modes
      " "
      mode-line-misc-info)))

  ;; Doom modeline
(use-package all-the-icons)
(use-package minions
  :hook (doom-modeline-mode . minions-mode)
  :custom
  (minions-mode-line-lighter ""))

(use-package doom-modeline
  :custom
  (doom-modeline-height 20)
  (doom-modeline-bar-width 5)
  (doom-modeline-lsp t)
  (doom-modeline-github nil)
  (doom-modeline-mu4e nil)
  (doom-modeline-irc nil)
  (doom-modeline-minor-modes t)
  (doom-modeline-persp-name nil)
  (doom-modeline-buffer-file-name-style 'truncate-except-project)
  (doom-modeline-icon t)
  (doom-modeline-buffer-state-icon t)
  (doom-modeline-buffer-modification-icon t)
  (doom-modeline-major-mode-icon t))
  (doom-modeline-mode 1)

;; Keychord
(use-package use-package-chords
  :disabled
  :config (key-chord-mode 1))

;; Notifications configuration
(use-package alert
  :commands alert
  :config
  (setq alert-default-style 'notifications))

;; Window configuration
  ;; Zooming
  ;; The keybindings for this are C-M-- and C-M-=
(use-package default-text-scale
  :defer 1
  :config
  (default-text-scale-mode))
  ;; Window selection
(use-package ace-window
  :bind (("M-o" . ace-window))
  :config
  (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))

  ;; Window history
(winner-mode)
(define-key evil-window-map "u" 'winner-undo)

  ;; Split/Delete
(leader-key-def
  "w"   '(:ignore t :which-key "window")
  "ws"   '(:ignore t :which-key "split")
  "wsj" '(split-window-below :which-key "split window below")
  "wsl" '(split-window-right :which-key "split window right")
  "wd"   '(:ignore t :which-key "delete")
  "wdd" '(delete-window :which-key "current window")
  "wdo" '(delete-other-windows :which-key "other windows"))

; Yasnippet configuration
(use-package yasnippet-snippets)
(use-package yasnippet
  :hook ((prog-mode . yas-minor-mode)
         (org-mode . yas-minor-mode))
  :config
  (yas-reload-all))

;; Corfu configuration
(use-package corfu
  :config
  (setq tab-always-indent 'complete
	corfu-popupinfo-delay t)
  :custom
  (corfu-auto t)
  (corfu-cycle t)
  :bind (:map corfu-map
	      ("C-j" . corfu-next)
	      ("C-k" . corfu-previous)
	      ("TAB" . corfu-insert)
	      ("M-<return>" . corfu-quit))
  :init
  (global-corfu-mode)
  (corfu-popupinfo-mode))

;; Completion At Point Extensions
(use-package cape
  :init
  ;; Add `completion-at-point-functions', used by `completion-at-point'.
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-history)
  (add-to-list 'completion-at-point-functions #'cape-keyword)
  (add-to-list 'completion-at-point-functions #'cape-tex)
  (add-to-list 'completion-at-point-functions #'cape-sgml)
  (add-to-list 'completion-at-point-functions #'cape-rfc1345)
  (add-to-list 'completion-at-point-functions #'cape-abbrev)
  (add-to-list 'completion-at-point-functions #'cape-ispell)
  (add-to-list 'completion-at-point-functions #'cape-symbol))

;; Solves the technical issues of Pcomplete
;; (extracted from the Corfu github page: 'https://github.com/minad/corfu')
;; The advices are only needed on Emacs 28 and older.
(when (< emacs-major-version 29)
  ;; Silence the pcomplete capf, no errors or messages!
  (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-silent)

  ;; Ensure that pcomplete does not write to the buffer
  ;; and behaves as a pure `completion-at-point-function'.
  (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-purify))

;; Buffers configuration
(leader-key-def
  "b"   '(:ignore t :which-key "buffers")
  "bb"  '(consult-buffer :which-key "switch buffer")
  "bw"  '(exwm-workspace-switch-to-buffer :which-key "switch workspace")
  "bn"  '(bury-buffer :which-key "bury buffer")
  "bm"  '(ibuffer :which-key "buffer menu")
  "bd"  '(:ignore t :which-key "kill buffer")
  "bdd" '(kill-current-buffer :which-key "current buffer")
  "bdo" '(kill-buffer :which-key "other buffer")
  "br"  '(rename-buffer :which-key "rename buffer"))

  ;; Ibuffer configuration
(add-hook 'ibuffer-mode-hook (lambda () (ibuffer-auto-mode 1) (ibuffer-switch-to-saved-filter-groups "default")))
(setq ibuffer-saved-filter-groups
      '(("default"
	 ("dired" (mode . dired-mode))
	 ("browser" (or
		     (name . "brave")
		     (name . "qutebrowser")))
	 ("git" (mode . magit-mode))
	 ("elisp" (mode . emacs-lisp-mode))
	 ("org" (mode . org-mode))
	 ("python" (mode . python-mode))
	 ("shell" (or
		   (mode . ansi-term-mode)
		   (mode . eshell-mode)
		   (mode . term-mode)
	  	   (mode . shell-mode)))
	 ("exwm" (mode . exwm-mode))
	 ("emacs" (name . "^[*].+[*]$"))))
      ibuffer-show-empty-filter-groups nil)

;; Expand region configuration
(use-package expand-region
  :bind (("M-[" . er/expand-region)
         ("M-{" . er/mark-outside-pairs)))

;; Dired configuration
  ;; Omit-mode
(use-package dired
  :ensure nil
  :defer 1
  :commands (dired dired-jump)
  :bind (("M-+" . dired-create-empty-file))
  :config
  (setq dired-listing-switches "-agho --group-directories-first"
        dired-omit-files "^\\.[^.].*"
        dired-omit-verbose nil))

(autoload 'dired-omit-mode "dired-x")

(add-hook 'dired-mode-hook
    (lambda ()
    (interactive)
    (dired-omit-mode 1)))

  ;; Dired design configuration
(use-package all-the-icons-dired)
(add-hook 'dired-mode-hook
  (lambda ()
  (interactive)
  (all-the-icons-dired-mode 1)
  (hl-line-mode 1)))

(add-hook 'dired-load-hook
  (lambda ()
  (interactive)
  (dired-collapse)))

(use-package dired-single
  :commands (dired dired-jump)
  :defer t)

(use-package dired-ranger
  :defer t)

(use-package dired-collapse
  :defer t)

;; Key bindings
(evil-collection-define-key 'normal 'dired-mode-map
  "h" 'dired-single-up-directory
  "H" 'dired-omit-mode
  "l" 'dired-single-buffer
  "y" 'dired-ranger-copy
  "n" 'dired-ranger-move
  "p" 'dired-ranger-paste)

;; Bindings for files
(leader-key-def
  "f"   '(:ignore t :which-key "files")
  "ff"  '(find-file :which-key "open file")
  "fr"  '(consult-recent-file :which-key "recent files")
  "fR"  '(revert-buffer :which-key "revert file")
  "fl"  '(load-file :which-key "load file")
  "fs"  '(save-buffer :which-key "save file")
  "fd"  '(dired :which-key "dired"))

;; Org mode configuration
(use-package org
  :defer t
  :config
  (org-babel-do-load-languages
    'org-babel-load-languages
    '((emacs-lisp . t)))

  ;; Org bullets
  (use-package org-bullets
  :after org
  :hook (org-mode . org-bullets-mode)
  :custom
  (org-bullets-bullet-list '("◉" "○")))

  ;; Key bindings
  (evil-define-key '(normal insert visual) org-mode-map (kbd "C-j") 'org-next-visible-heading)
  (evil-define-key '(normal insert visual) org-mode-map (kbd "C-k") 'org-previous-visible-heading)
  (evil-define-key '(normal insert visual) org-mode-map (kbd "M-j") 'org-metadown)
  (evil-define-key '(normal insert visual) org-mode-map (kbd "M-k") 'org-metaup))

  (use-package evil-org
  :after org
  :hook ((org-mode . evil-org-mode)
         (org-agenda-mode . evil-org-mode)
         (evil-org-mode . (lambda () (evil-org-set-key-theme '(navigation todo insert textobjects additional)))))
  :config
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))

(leader-key-def
  "o"   '(:ignore t :which-key "org")
  "om"  '(org-mode :which-key "mode")
  "oi"  '(:ignore t :which-key "insert")
  "oil" '(org-insert-link :which-key "insert link")
  "on"  '(org-toggle-narrow-to-subtree :which-key "toggle narrow")
  "oa"  '(org-agenda :which-key "agenda")
  "oc"  '(org-capture t :which-key "capture")
  "oe"  '(org-export-dispatch t :which-key "export"))

  ;; Literate Calculations in Org Mode
(use-package literate-calc-mode
  :hook (org-mode . literate-calc-minor-mode))

;; Darkroom configuration
(use-package darkroom
  :commands darkroom-mode
  :config
  (setq darkroom-text-scale-increase 0))

(leader-key-def
  "tf" '(darkroom-mode :which-key "focus mode"))

;; Daemons administration
(use-package daemons
  :commands daemons)

;; Proced
(use-package proced
  :commands proced
  :config
  (setq proced-auto-update-interval 1)
  (add-to-list 'proced-format-alist
	       '(custom user pid ppid sess tree pcpu pmem rss start time state (args comm)))
  (setq-default proced-format 'custom)
  (add-hook 'proced-mode-hook
            (lambda ()
              (proced-toggle-auto-update 1))))

;; Eshell configuration
(use-package evil-collection-eshell
  :ensure nil
  :init
  (evil-collection-eshell-setup))

  ;; Fish Completions
(use-package fish-completion
  :hook (eshell-mode . fish-completion-mode))

  ;; Command Highlighting
  (use-package eshell-syntax-highlighting
  :config
  (eshell-syntax-highlighting-global-mode +1))

  ;; Toggle eshell at the bottom of a buffer
  (use-package eshell-toggle
    :custom
    (eshell-toggle-size-fraction 3)
    (eshell-toggle-run-command nil))

  ;; Make Corfu act like most shells completions
  (add-hook 'eshell-mode-hook
            (lambda ()
              (setq-local corfu-auto nil)
              (corfu-mode)))

  ;; Visual Commands
(with-eval-after-load 'esh-opt
 (setq eshell-destroy-buffer-when-process-dies t)
 (setq eshell-visual-commands '("git" "gh" "pass" "emacs")))

;; Stop Async Shell commands from split the window
(add-to-list 'display-buffer-alist
  '("\\*Async Shell Command\\*.*" display-buffer-no-window))

;; Tracking
(use-package tracking
  :defer t
  :config
  (setq tracking-frame-bahavior nil))

;; Telegram
;;(use-package telega
;;  :commands telega
;;  :config
;;  (setq telega-use-tracking-for '(any pin unread)))
;;(telega-notifications-mode 1)

;; Dunst
(defun history-pop ()
  (interactive)
  (start-process-shell-command "dunstctl" nil "dunstctl history-pop"))

(defun close-all ()
  (interactive)
  (start-process-shell-command "dunstctl" nil "dunstctl close-all"))

(defun toggle-desktop-notification ()
  (interactive)
  (start-process-shell-command "dunstctl" nil "dunstctl set-paused toggle"))

(exwm-key-input
 '(("s-h" . history-pop)
   ("s-c" . close-all)
   ("s-t" . toggle-desktop-notification)))

;; "Shell" modes mode
(leader-key-def
  "s"	'(:ignore t :which-key "shells")
  "se"	'(eshell :which-key "eshell")
  "ss"	'(shell :which-key "shell"))

;; KDE Connect
(use-package kdeconnect
  :config
  (setq kdeconnect-devices "fe5c4316cee0e91f"
	kdeconnect-active-device "fe5c4316cee0e91f")
  (leader-key-def
    "k" '(:ignore t :which-key "kdeconnect")
    "ks" '(kdeconnect-send-file :which-key "send file")
    "kf" '(kdeconnect-ring :which-key "find phone")
    "kt" '(kdeconnect-send-text-region-or-prompt :which-key "send text")))

;; Better Help buffers with Helpful
(use-package helpful
  :bind
  ("C-h f" . helpful-function)
  ("C-h v" . helpful-variable)
  ("C-h k" . helpful-key)
  ("C-h x" . helpful-command)
  ("C-h m" . helpful-macro)
  ("C-h q" . helpful-kill-buffers)
  ("C-h C-c" . helpful-callable)
  ("C-c C-d" . helpful-at-point))

;; Automatically clean whitespace
(use-package ws-butler
  :hook ((prog-mode . ws-butler-mode)
	 (text-mode . ws-butler-mode)))

;; Using git in Emacs

  ;; Magit
 (use-package magit
   :custom
   magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)

 ;; Make Magit more powerful with Forge
 (use-package forge)

 ;; Showing todos in Magit
 (use-package magit-todos)

 ;; Opening Git files externally
 (use-package git-link
   :config
   (setq git-link-open-in-browser t))
