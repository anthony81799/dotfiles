;;; lisp/options.el -*- lexical-binding: t; -*-

;; reuse the LSP servers, linters and formatters Mason installed for nvim
(let ((mason-bin (expand-file-name "~/.local/share/nvim/mason/bin")))
  (when (file-directory-p mason-bin)
    (add-to-list 'exec-path mason-bin)
    (setenv "PATH" (concat mason-bin path-separator (getenv "PATH")))))

;; gopls reports filetype "gotmpl" for Go template files
(add-to-list 'auto-mode-alist '("\\.tmpl\\'" . web-mode))
(setq web-mode-engines-alist '(("go" . "\\.tmpl\\'")))

(setq doom-theme 'doom-gruvbox
      doom-gruvbox-dark-variant "hard"
      doom-font (font-spec :family "JetBrainsMono Nerd Font" :weight 'semi-bold :size 16)
      nerd-icons-font-family "JetBrainsMono Nerd Font Mono")

(setq display-line-numbers-type 'relative
      scroll-margin 10
      hscroll-margin 10
      scroll-conservatively 101
      standard-indent 4
      evil-ex-search-case 'smart
      evil-ex-search-persistent-highlight t
      evil-split-window-below t
      evil-vsplit-window-right t
      make-backup-files nil
      create-lockfiles nil
      auto-save-default nil
      auto-revert-verbose nil
      select-enable-clipboard t
      ring-bell-function #'ignore
      ;; only prompt on quit when buffers are unsaved
      confirm-kill-emacs nil)

(setq-default truncate-lines t
              tab-width 4
              indent-tabs-mode nil
              fill-column 80)

(global-auto-revert-mode 1)
(add-hook 'prog-mode-hook #'display-fill-column-indicator-mode)

;; iskeyword+=-
(add-hook! '(prog-mode-hook text-mode-hook)
  (defun +my/dash-is-word-h () (modify-syntax-entry ?- "w")))
