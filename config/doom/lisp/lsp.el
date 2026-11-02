;;; lisp/lsp.el -*- lexical-binding: t; -*-

(setq lsp-ui-sideline-enable nil
      lsp-ui-sideline-show-diagnostics nil
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
  '(python-flake8 sh-shellcheck lua-luacheck javascript-eslint javascript-oxlint c/c++-googlelint go-revive))

;; eslint by default; oxlint (and no eslint, flycheck or lsp) when the project installs it
(defun +my/js-linter-h ()
  (let ((root (and buffer-file-name
                   (locate-dominating-file buffer-file-name "node_modules/.bin/oxlint"))))
    (setq-local flycheck-disabled-checkers
                (cons (if root 'javascript-eslint 'javascript-oxlint) flycheck-disabled-checkers))
    (when root
      (setq-local flycheck-javascript-oxlint-executable (expand-file-name "node_modules/.bin/oxlint" root)
                  lsp-eslint-enable nil))))
(add-hook! '(js-mode-hook js-ts-mode-hook typescript-mode-hook typescript-ts-mode-hook tsx-ts-mode-hook rjsx-mode-hook)
           #'+my/js-linter-h)

;; TypeScript 7+ ships no tsserver for ts-ls; serve LSP from the project's own `tsc --lsp' instead
(defun +my/ts-native-lsp-h ()
  (when-let* ((root (and buffer-file-name
                         (locate-dominating-file buffer-file-name "node_modules/typescript/package.json")))
              ((not (file-exists-p (expand-file-name "node_modules/typescript/lib/tsserver.js" root)))))
    (setq-local lsp-clients-tsgo-path (expand-file-name "node_modules/.bin/tsc" root)
                lsp-disabled-clients (cons 'ts-ls (bound-and-true-p lsp-disabled-clients)))))
(add-hook! '(js-mode-hook js-ts-mode-hook typescript-mode-hook typescript-ts-mode-hook tsx-ts-mode-hook rjsx-mode-hook)
           #'+my/ts-native-lsp-h)

;; vc-gutter pins flycheck to the right fringe, which terminals don't have
(add-hook! 'flycheck-mode-hook
  (defun +my/flycheck-tty-margin-h ()
    (unless (display-graphic-p)
      (flycheck-set-indication-mode 'right-margin))))

;; nvim virtual_text: `●' per diagnostic + most severe message at the end of every line
(defface +my/eol-error   '((t :foreground "#fb5944")) "")
(defface +my/eol-warning '((t :foreground "#fe8019")) "")
(defface +my/eol-info    '((t :foreground "#83a598")) "")

(defun +my/flycheck-eol-render-h ()
  (remove-overlays (point-min) (point-max) '+my/eol t)
  (when flycheck-mode
    (let ((lines (make-hash-table)))
      (dolist (e flycheck-current-errors)
        (unless (flycheck-relevant-error-other-file-p e)
          (push e (gethash (flycheck-error-line e) lines))))
      (save-excursion
        (maphash
         (lambda (line errs)
           (setq errs (sort errs (lambda (a b) (> (flycheck-error-level-severity (flycheck-error-level a))
                                                  (flycheck-error-level-severity (flycheck-error-level b))))))
           (let* ((top (car errs))
                  (face (pcase (flycheck-error-level top)
                          ('error '+my/eol-error) ('warning '+my/eol-warning) (_ '+my/eol-info)))
                  (msg (car (split-string (or (flycheck-error-message top) "") "\n")))
                  (ov (progn (goto-char (point-min)) (forward-line (1- line))
                             (make-overlay (line-end-position) (line-end-position)))))
             (overlay-put ov '+my/eol t)
             (overlay-put ov 'after-string
                          (concat "    " (propertize (concat (mapconcat (lambda (_) "●") errs " ") " " msg)
                                                   'face face)))))
         lines)))))
(add-hook! 'flycheck-after-syntax-check-hook #'+my/flycheck-eol-render-h)
(add-hook! 'flycheck-mode-hook #'+my/flycheck-eol-render-h)

(defadvice! +my/lsp-inline-completion-object-a (caps)
  "lsp-mode sends `inlineCompletion: null', which tsgo rejects; send an object."
  :filter-return #'lsp--client-capabilities
  (let ((caps (copy-tree caps)))
    (setf (alist-get 'inlineCompletion (alist-get 'textDocument caps))
          '((dynamicRegistration . :json-false)))
    caps))

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

;; lsp-mode ships a just-lsp client; it only needs starting
(add-hook 'just-mode-local-vars-hook #'lsp! 'append)

;; guess the root from .git/projectile instead of prompting; files outside a project start without a root
(setq lsp-auto-guess-root t)
