;;; lisp/autocmds.el -*- lexical-binding: t; -*-

;; format on save with the same tools efm used in nvim
(after! apheleia
  (set-formatter! 'prettierd '("prettierd" filepath)
    :modes '(js-mode js-ts-mode js2-mode rjsx-mode typescript-mode typescript-ts-mode
             tsx-ts-mode css-mode css-ts-mode scss-mode html-mode html-ts-mode web-mode))
  (set-formatter! 'fixjson '("fixjson")
    :modes '(json-mode json-ts-mode jsonc-mode))
  (set-formatter! 'gofumpt '("gofumpt")
    :modes '(go-mode go-ts-mode))
  (set-formatter! 'stylua :modes '(lua-mode lua-ts-mode))
  (set-formatter! 'black :modes '(python-mode python-ts-mode))
  (set-formatter! 'shfmt :modes '(sh-mode bash-ts-mode))
  (set-formatter! 'clang-format :modes '(c-mode c-ts-mode c++-mode c++-ts-mode)))

;; nvim's BufWritePre pattern list skipped these
(setq +format-on-save-disabled-modes
      (append '(markdown-mode gfm-mode rust-mode rust-ts-mode rustic-mode
                yaml-mode yaml-ts-mode toml-ts-mode conf-toml-mode)
              +format-on-save-disabled-modes))

;; wrap, linebreak and spellcheck on markdown and text files
(add-hook 'text-mode-hook #'visual-line-mode)

;; mini.cursorword
(add-hook 'prog-mode-hook #'idle-highlight-mode)
