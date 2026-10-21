;;; lisp/lsp.el -*- lexical-binding: t; -*-

(setq lsp-ui-sideline-enable t
      lsp-ui-sideline-show-diagnostics t
      lsp-ui-sideline-show-code-actions nil
      lsp-ui-sideline-show-hover nil
      lsp-ui-doc-enable nil
      lsp-clients-lua-language-server-command '("lua-language-server"))

;; retrobox palette, same as the nvim Diagnostic* overrides
(custom-set-faces!
  '(flycheck-error   :underline (:style wave :color "#fb5944"))
  '(flycheck-warning :underline (:style wave :color "#fe8019"))
  '(flycheck-info    :underline (:style wave :color "#83a598"))
  '(flycheck-fringe-error   :foreground "#fb5944")
  '(flycheck-fringe-warning :foreground "#fe8019")
  '(flycheck-fringe-info    :foreground "#83a598"))

(after! flycheck
  (setq flycheck-javascript-eslint-executable "eslint_d")
  (flycheck-define-checker go-revive
    "Go linter using revive."
    :command ("revive" source-original)
    :error-patterns ((warning line-start (file-name) ":" line ":" column ": " (message) line-end))
    :modes (go-mode go-ts-mode)
    :predicate flycheck-buffer-saved-p)
  (add-to-list 'flycheck-checkers 'go-revive t))

(use-package! flycheck-google-cpplint
  :after flycheck
  :config (setq flycheck-googlelint-verbose "3"))

;; lsp-mode replaces the buffer's checker with `lsp'; chain the efm linters after it
(defvar +my/lsp-linters
  '(python-flake8 sh-shellcheck lua-luacheck javascript-eslint c/c++-googlelint go-revive))

(defvar +my/lsp-linters-chained nil)
(add-hook! 'lsp-diagnostics-mode-hook
  (defun +my/chain-lsp-linters-h ()
    (when (and (not +my/lsp-linters-chained) (flycheck-valid-checker-p 'lsp))
      (dolist (c +my/lsp-linters)
        (when (flycheck-valid-checker-p c)
          (flycheck-add-next-checker 'lsp `(warning . ,c) t)))
      (setq +my/lsp-linters-chained t))))

;; blink.cmp auto_show is off in markdown
(add-hook '+corfu-inhibit-auto-functions (lambda () (derived-mode-p 'markdown-mode)))

;; guess the root from .git/projectile instead of prompting; files outside a project start without a root
(setq lsp-auto-guess-root t)
