;;; lisp/statusline.el -*- lexical-binding: t; -*-

;; doom-modeline already shows file size (size-indication-mode) and vcs branch
(setq doom-modeline-modal t
      doom-modeline-modal-icon t
      doom-modeline-major-mode-icon t
      doom-modeline-buffer-file-name-style 'relative-to-project
      doom-modeline-percent-position '(-3 "%p"))

(column-number-mode 1)
