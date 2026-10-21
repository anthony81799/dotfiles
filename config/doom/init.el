;;; $DOOMDIR/init.el -*- lexical-binding: t; -*-

(doom! :completion
       (corfu +orderless +icons)
       (vertico +icons)

       :ui
       doom
       dashboard
       hl-todo
       indent-guides
       modeline
       ophints
       (popup +defaults)
       (vc-gutter +pretty)
       zen

       :editor
       (evil +everywhere)
       file-templates
       fold
       (format +onsave)
       snippets
       (whitespace +guess +trim)

       :emacs
       (dired +dirvish +icons)
       electric
       undo
       vc

       :term
       vterm

       :checkers
       syntax
       (spell +flyspell +hunspell)

       :tools
       lookup
       lsp
       magit
       tree-sitter

       :os
       tty

       :lang
       (cc +lsp +tree-sitter)
       emacs-lisp
       (go +lsp +tree-sitter)
       (javascript +lsp +tree-sitter)
       (json +lsp +tree-sitter)
       (lua +lsp +tree-sitter)
       markdown
       (python +lsp +pyright +tree-sitter)
       (rust +lsp +tree-sitter)
       (sh +lsp)
       (web +lsp +tree-sitter)

       :config
       (default +bindings +smartparens))
