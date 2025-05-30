;; -*- lexical-binding: t; -*-

;; Emacs initialization
(setq inhibit-startup-message t 		    ; Disable the startup message
      column-number-indicator-zero-based nil        ; Column number starts at one
      native-comp-async-report-warnings-errors nil  ; Silence Compiler warnings
      package-install-upgrade-built-in t            ; Upgrade the built-in packages
      ;; Proper fullscreen handler
      ns-use-native-fullscreen t
      ;; Right option working as default
      ns-right-alternate-modifier nil
      ;; Clipboard support
      select-enable-clipboard t
      save-interprogram-paste-before-kill t)

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
      scroll-margin 5)				   ; set the margin to five lines

;; Set frame transparency and maximize windows by default
(set-frame-parameter (selected-frame) 'alpha '(90 . 90))
(add-to-list 'default-frame-alist '(alpha . (90 . 90)))
(add-to-list 'default-frame-alist '(fullscreen . maximized))
(add-to-list 'default-frame-alist '(undecorated . t))

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
(setq package-archives '(("elpa"	 . "https://elpa.gnu.org/packages/")
			 ("nongnu-elpa"	 . "https://elpa.nongnu.org/nongnu/")
			 ("melpa-stable" . "https://stable.melpa.org/packages/")
			 ("melpa"	 . "https://melpa.org/packages/")))
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Emacs theme
(load-theme 'Sholum t)

;; Use-package configuration
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
  "Major modes on which to disable the linum mode, exempts them from global requirement."
  :group 'display-line-numbers
  :type 'list
  :version "green")

(defun display-line-numbers--turn-on ()
  "Turn on line numbers but except certain major modes defined in `display-line-numbers-exempt-modes'."
  (if (and
       (not (member major-mode display-line-numbers-exempt-modes))
       (not (minibufferp)))
      (display-line-numbers-mode)))

(global-display-line-numbers-mode)

;; Give emacs the ENV from Shell
(use-package exec-path-from-shell
  :config
  (exec-path-from-shell-initialize))

;; Dashboard configuration
(use-package dashboard
  :demand t
  :config
  (setq dashboard-banner-logo-title "Welcome to Emacs, Sholum"
	dashboard-startup-banner 'logo
	dashboard-set-init-info t
	dashboard-center-content t
	dashboard-icon-type 'all-the-icons
	dashboard-items '((recents . 10)
			  (agenda . 15)
			  (bookmarks . 5)))
  (dashboard-setup-startup-hook))

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
  (setq which-key-idle-delay 0.1
	which-key-allow-evil-operators t))

  ;; ESC cancels all
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

;; Rebind C-u (since evil take it over)
(global-set-key (kbd "C-M-u") 'universal-argument)

;; Using git in Emacs

  ;; Magit
  (use-package magit
    :custom
    magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)

 ;; Make Magit more powerful with Forge
  (use-package forge
    :after magit)

 ;; Opening Git files externally
 (use-package git-link
   :config
   (setq git-link-open-in-browser t))

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
  (setq undo-tree-history-directory-alist
	`(("." . ,(expand-file-name "undo" user-emacs-directory)))))

;; Hydra
(use-package hydra
  :defer 1)

;; Completions with Vertico
(defun minibuffer-backward-kill (arg)
  "When minibuffer is completing a file name delete up to parent folder, otherwise delete a word."
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
  :config (setq history-length             25
	        history-delete-duplicates  t
		savehist-ignored-variables '(shell-command-history)))

;; Consult configuration
(use-package consult
  :bind ("C-s" . consult-line))

(leader-key-def
  "c"	'(:ignore t			:which-key "consult")
  "cy"	'(consult-yank-from-kill-ring	:which-key "kill ring")
  "cl"	'(consult-goto-line		:which-key "goto line")
  "ci"	'(consult-imenu			:which-key "imenu")
  "cg"  '(consult-grep  		:which-key "grep")
  "cl"  '(consult-goto-line		:which-key "goto line")
  "cf"  '(consult-locate		:which-key "locate")
  "cm"	'(evil-collection-consult-mark	:which-key "mark history")
  "ce"	'(:ignore t			:which-key "error")
  "cem" '(consult-flymake		:which-key "flymake")
  "cec" '(consult-flycheck		:which-key "flycheck"))

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

;; Change theme / White space mode
(leader-key-def
  "t"  '(:ignore t :which-key "toggles")
  "tw" '(whitespace-mode :which-key "whitespace")
  "te" '(eshell-toggle :which-key "eshell"))

;; Highlight Matching Braces
(use-package paren
  :config
  (set-face-attribute 'show-paren-match-expression nil :background "#36454f")
  (show-paren-mode 1))

;; Smart Parens
(use-package smartparens
  :hook (prog-mode org-mode)
  :config
  (require 'smartparens-config)
  (sp-use-paredit-bindings)
  (sp-pair "\"" "\"" :wrap "M-\"")
  (sp-pair "'" "'" :wrap "M-'")
  (sp-pair "[" "]" :wrap "M-[")
  (sp-pair "{" "}" :wrap "M-{")
  (sp-with-modes '(c-mode c-ts-mode c++-mode c++-ts-mode)
    (sp-local-pair  " " " " :wrap "M-SPC" :actions '(wrap))))

;; Rainbow delimiters
(use-package rainbow-delimiters
  :hook ((prog-mode . rainbow-delimiters-mode)
         (org-mode . rainbow-delimiters-mode)))

;; Rainbow mode
(use-package rainbow-mode
  :defer t
  :hook (org-mode))

;; Flymake configuration
(use-package flymake
  :defer t
  :hook ((org-mode . flymake-mode)
	 (prog-mode . flymake-mode)))

;; Flycheck configuration
(use-package flycheck
  :config (setq-default flycheck-disabled-checkers '(haskell-stack-ghc)))

(use-package consult-flycheck
  :after flycheck)
(global-flycheck-mode)

;; TRAMP
  ;; Set default connection mode to SSH
(setq tramp-default-method "ssh")

;;
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
(use-package nerd-icons
  :config
  (setq nerd-icons-scale-factor 1.3))

(use-package minions
  :hook (doom-modeline-mode . minions-mode)
  :custom
  (minions-mode-line-lighter ""))

(use-package doom-modeline
  :custom
  (doom-modeline-enable-word-count t)
  (doom-modeline-height 23)
  (doom-modeline-bar-width 5)
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

;; This is dangerous because it replaces a default keybinding (vc-prefix);
;;  use this only if you don't use too many version control commands.
(global-set-key (kbd "C-x v") 'shrink-window)

; Yasnippet configuration
(use-package yasnippet-snippets)
(use-package yasnippet
  :hook ((prog-mode . yas-minor-mode)
         (org-mode . yas-minor-mode))
  :config
  (yas-reload-all))

;; Corfu configuration
(use-package corfu
  ;; :hook (corfu-mode . corfu-popupinfo-mode)
  :config
  (setq corfu-popupinfo-delay t
	tab-always-indent 'complete)
  :custom
  (corfu-auto t)
  (corfu-cycle t)
  :bind (:map corfu-map
	      ("C-j" . corfu-next)
	      ("C-k" . corfu-previous)
	      ("TAB" . corfu-insert)
	      ([tab] . corfu-insert)
	      ("M-<return>" . corfu-quit))
  :init
  (global-corfu-mode)
  :config
  (keymap-unset corfu-map "RET"))

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
  (add-to-list 'completion-at-point-functions #'cape-abbrev))

;; Buffers configuration
(leader-key-def
  "b"   '(:ignore t :which-key "buffers")
  "bb"  '(consult-buffer :which-key "switch buffer")
  "bn"  '(bury-buffer :which-key "bury buffer")
  "bm"  '(ibuffer :which-key "buffer menu")
  "bd"  '(:ignore t :which-key "kill buffer")
  "bdd" '(kill-current-buffer :which-key "current buffer")
  "bdo" '(kill-buffer :which-key "other buffer")
  "br"  '(rename-buffer :which-key "rename buffer"))

  ;; Ibuffer configuration
(add-hook 'ibuffer-mode-hook
	  (lambda ()
	    (ibuffer-auto-mode 1)
	    (ibuffer-switch-to-saved-filter-groups "default")))
(setq ibuffer-saved-filter-groups
      '(("default"
	 ("dired"	    (mode . dired-mode))
	 ("browser"	    (or
		             (name . "brave")
			     (name . "qutebrowser")))
	 ("elisp"	    (mode . emacs-lisp-mode))
	 ("org"		    (mode . org-mode))
	 ("python"	    (mode . python-mode))
	 ("java"	    (mode . java-mode))
	 ("lisp"            (or
			     (mode . common-lisp-mode)
			     (mode . lisp-mode)))
	 ("clojure(script)" (or (mode . clojure-mode)
				(mode . clojurescript-mode)
				(mode . clojurec-mode)))
	 ("scheme"	    (mode . scheme-mode))
	 ("haskell"	    (or
			     (mode . haskell-mode)
			     (mode . haskell-interactive-mode)))
	 ("c/cpp"	    (or
			     (mode . c-mode)
			     (mode . c++-mode)))
	 ("shell"	    (or
			     (mode . ansi-term-mode)
			     (mode . eshell-mode)
			     (mode . term-mode)
			     (mode . shell-mode)))
	 ("git"		    (name . "^magit"))
	 ("telegram"	    (or
			     (mode . telega-chat-mode)
			     (mode . telega-root-mode)))
	 ("don't kill"	    (or
			     (mode . dashboard-mode)
			     (name . "*scratch*")))
	 ("emacs"	    (name . "^[*].+[*]$"))))
      ibuffer-show-empty-filter-groups nil)

;; Expand region configuration
(use-package expand-region
  :bind (("s-[" . er/expand-region)
	 ("s-{" . er/mark-outside-pairs)))

;; Dired configuration
(setq insert-directory-program "gls" dired-use-ls-dired t)
(setq dired-listing-switches "-al --group-directories-first")

(use-package all-the-icons)
(use-package all-the-icons-dired)
(use-package dired-ranger
  :defer t)

(use-package dired
  :ensure nil
  :defer l
  :bind (:map dired-mode-map
	      ("M-+" . dired-create-empty-file))
  :commands (dired dired-jump)
  :config
  (setq dired-listing-switches "-agho --group-directories-first"
        dired-omit-files "^\\.[^.].*"
        dired-omit-verbose nil
	dired-dwim-target 'dired-dwim-target-next
	dired-kill-when-opening-new-dired-buffer t
	delete-by-moving-to-trash t)
  (evil-collection-define-key 'normal 'dired-mode-map
    "h" 'dired-up-directory
    "H" 'dired-omit-mode
    "l" 'dired-find-file
    "y" 'dired-ranger-copy
    "n" 'dired-ranger-move
    "p" 'dired-ranger-paste)
  :hook
  (dired-mode . (lambda ()
		  (interactive)
		  (all-the-icons-dired-mode 1)
		  (hl-line-mode 1)
		  (dired-omit-mode 1))))

(use-package diredfl
  :hook (dired-mode . diredfl-mode))

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
    '((emacs-lisp . t)
      (python . t)))

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
  "on"  '(org-toggle-narrow-to-subtree :which-key "toggle narrow")
  "oa"  '(org-agenda :which-key "agenda")
  "oc"  '(org-capture t :which-key "capture")
  "oe"  '(org-export-dispatch t :which-key "export"))

  ;; Literate Calculations in Org Mode
  (use-package literate-calc-mode
    :hook (org-mode . literate-calc-minor-mode))


;; Reveal.js configuration
(use-package org-re-reveal
  :config
  (setq org-re-reveal-root "file:///home/sholum/.reveal.js/"))

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
  (setq proced-auto-update-interval 1
	proced-enable-color-flag t)
  (add-to-list 'proced-format-alist
	       '(custom user pid ppid sess tree pcpu pmem rss start time state (args comm)))
  (setq-default proced-format 'custom)
  (add-hook 'proced-mode-hook
            (lambda ()
              (proced-toggle-auto-update 1))))

;; Eshell configuration
(use-package eshell
  :config
  (setq eshell-aliases-file
	(expand-file-name "~/.emacs.d/eshell/alias")))

(use-package evil-collection-eshell
  :ensure nil
  :init
  (evil-collection-eshell-setup))

(defun eshell-instance ()
  (interactive)
  (eshell 'N))

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

  ;; Eat
  (use-package eat
    :config
    (add-hook 'eshell-load-hook #'eat-eshell-mode)
    (add-hook 'eshell-load-hook #'eat-eshell-visual-command-mode))

;; Term
(defun ansi-term-instance ()
  (interactive)
  (ansi-term "bash"))

;; "Shell" modes mode
(leader-key-def
  "s"  '(:ignore t          :which-key "shells")
  "se" '(eshell-instance    :which-key "eshell")
  "ss" '(shell              :which-key "shell")
  "st" '(ansi-term-instance :which-key "term"))

;; Stop Async Shell commands from split the window
(add-to-list 'display-buffer-alist
  '("\\*Async Shell Command\\*.*" display-buffer-no-window))

;; Tracking
(use-package tracking
  :defer t
  :config
  (setq tracking-frame-bahavior nil))

;; Better Help buffers with Helpful
(use-package helpful
  :bind
  ("C-h f"   . helpful-function)
  ("C-h v"   . helpful-variable)
  ("C-h k"   . helpful-key)
  ("C-h x"   . helpful-command)
  ("C-h m"   . helpful-macro)
  ("C-h q"   . helpful-kill-buffers)
  ("C-h C-c" . helpful-callable)
  ("C-c C-d" . helpful-at-point))

;; Automatically clean whitespace
(use-package ws-butler
  :hook ((prog-mode . ws-butler-mode)
	 (text-mode . ws-butler-mode)))

;; Better spell checking with jinx
(use-package jinx
  :hook (emacs-startup . global-jinx-mode)
  :bind ([remap ispell-word] . jinx-correct))

;; Language Server Protocol (Eglot) configuration
(defvar sh/organize? nil)

(defun activate-eglot-organize-file ()
  (when (eglot--current-project)
    (add-hook 'before-save-hook #'eglot-code-action-organize-imports nil t)
    (add-hook 'before-save-hook 'eglot-format-buffer nil t)
    (setq sh/organize? t)
    (message "Eglot will format the file on save")))

(defun deactivate-eglot-organize-file ()
  (when (eglot--current-project)
    (remove-hook 'before-save-hook #'eglot-code-action-organize-imports t)
    (remove-hook 'before-save-hook 'eglot-format-buffer t)
    (setq sh/organize? nil)
    (message "Eglot will not format the file on save")))

(defun toggle-eglot-organize-file ()
  (interactive)
  (if sh/organize?
      (deactivate-eglot-organize-file)
    (activate-eglot-organize-file)))

(use-package eglot
  :defer t
  :hook ((c-mode             . eglot-ensure)
         (haskell-mode       . eglot-ensure)
         (python-mode        . eglot-ensure)
         (prolog-mode        . eglot-ensure)
         (clojure-mode       . eglot-ensure)
         (clojurescript-mode . eglot-ensure)
         (clojurec-mode      . eglot-ensure)
	 (typescript-mode    . eglot-ensure)
         (eglot-managed-mode . activate-eglot-organize-file))
  :config
  (advice-add 'eglot-completion-at-point :around #'cape-wrap-buster)
  (setopt eglot-server-programs (cons
                                 (cons 'prolog-mode
                                       (list "swipl"
                                             "-O"
                                             "-g" "use_module(library(lsp_server))."
                                             "-g" "lsp_server:main"
                                             "-t" "halt"
                                             "--" "port" :autoport))
                                 eglot-server-programs))
  (setq eglot-ignored-server-capabilities '(:hoverProvider))
  (define-key eglot-mode-map (kbd "C-c o") 'toggle-eglot-organize-file))

;; C configuration
(defun compile-c ()
  (interactive)
  (save-buffer)
  (let ((project-dir (locate-dominating-file (buffer-file-name) "makefile")))
    (if project-dir
	(progn (setq default-directory project-dir)
               (compile (format "make")))
      (compile (format "clang '%s' -O0 -g -o '%s'" (buffer-name) (file-name-sans-extension (buffer-name)))))))

(defun compile-riscv ()
  (interactive)
  (save-buffer)
  (compile (format "clang --target=riscv32 -march=rv32g -mabi=ilp32d -mno-relax '%s' -S -o '%s.s'"
		   (buffer-name) (file-name-sans-extension (buffer-name)))))

(add-hook 'c-mode-hook
	  (lambda()
	    (define-key c-mode-map (kbd "C-c C-c") 'compile-c)
	    (define-key c-mode-map (kbd "C-c C-v") 'compile-riscv)))

;; Haskell
(use-package haskell-mode
  :hook ((haskell-mode . haskell-indentation-mode)
	 (haskell-mode . interactive-haskell-mode))
  :config
  (setq haskell-process-type 'ghci))

(use-package hlint-refactor
  :hook (haskell-mode . hlint-refactor-mode))

;; Java
(use-package eglot-java
  :hook (eglot-java-mode . java-mode))

;; Direnv
(use-package envrc
  :bind (:map envrc-mode-map
	      ("C-c e" . envrc-command-map))
  :hook (after-init . envrc-global-mode))

;; Move Text
(use-package drag-stuff
  :bind
  (("C-S-k" . drag-stuff-up))
  ("C-S-j" . drag-stuff-down)
  :config (drag-stuff-global-mode t))

;; Prolog
(setq prolog-system 'swi
      prolog-electric-if-then-else-flag t)

(use-package ediprolog
  :config
  (setq ediprolog-system 'swi))

(defun prolog-insert-comment-block ()
  "Insert a PceEmacs-style comment block like /* - - ... - - */ "
  (interactive)
  (let ((dashes "-"))
    (dotimes (_ 36) (setq dashes (concat "- " dashes)))
    (insert (format "/* %s\n\n%s */" dashes dashes))
    (forward-line -1)
    (indent-for-tab-command)))

(add-hook 'prolog-mode-hook
	  (lambda()
	    (define-key prolog-mode-map (kbd "C-c c") 'prolog-insert-comment-block)
	    (define-key prolog-mode-map (kbd "C-c l") '(lambda ()
							 (interactive)
							 (insert ":- use_module(library()).")
							 (forward-char -3)))
	    (define-key prolog-mode-map (kbd "C-c C-e") 'ediprolog-dwim)))

(add-to-list 'auto-mode-alist '("\\.pl\\'" . prolog-mode))

;; Common Lisp
(use-package sly
  :hook ((common-lisp-mode . sly-mode)
	 (lisp-mode . sly-mode))
  :config (add-hook 'sly-mode-hook
          (lambda ()
            (unless (sly-connected-p)
              (save-excursion (sly)))))
  (setq inferior-lisp-program "~/opt/sbcl/bin/sbcl"))

;; Clojure
(use-package cider
  :hook (clojure-mode clojurescript-mode clojurec-mode)
  :bind (:map cider-repl-mode-map
	      ("C-c C-b" . cider-repl-switch-to-other)
	      ("C-c M-o" . cider-repl-clear-buffer))
  :config (setq cider-repl-display-help-banner nil))

;; Scheme (Guile)
(defun clear-geiser-history ()
  "Clear geiser repl history."
  (interactive)
  (let ((history-files
	 (directory-files user-emacs-directory t "geiser-history\\..*" t)))
    (dolist (file history-files)
      (when (file-exists-p file)
        (delete-file file)))))

(use-package geiser
  :config
  (setq geiser-repl-history-filename
	(expand-file-name "geiser-history" user-emacs-directory))
  ;; The geiser repl doesn't have a kill/quit hook, so I decided to
  ;; clear the history on the startup.
  (add-hook 'geiser-repl-mode-hook #'clear-geiser-history))

(use-package geiser-guile)

;; ASM
(setq asm-comment-char 35)

;; Typescript
(use-package typescript-mode
  :mode (("\\.ts\\'"  . typescript-mode)))

;; Tide
(use-package tide
  :ensure t
  :config
  (defun setup-tide-mode ()
    (interactive)
    (tide-setup)
    (flycheck-mode +1)
    (setq flycheck-check-syntax-automatically '(save mode-enabled))
    (eldoc-mode +1)
    (tide-hl-identifier-mode +1))
  :hook ((typescript-mode . tide-setup)
         (typescript-mode . tide-hl-identifier-mode)
         (before-save . tide-format-before-save)))

(dashboard-refresh-buffer)
