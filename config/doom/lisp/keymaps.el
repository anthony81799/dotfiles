;;; lisp/keymaps.el -*- lexical-binding: t; -*-

(defun +my/down-wrap-aware (&optional count)
  (interactive "P")
  (if count (evil-next-line (prefix-numeric-value count)) (evil-next-visual-line)))

(defun +my/up-wrap-aware (&optional count)
  (interactive "P")
  (if count (evil-previous-line (prefix-numeric-value count)) (evil-previous-visual-line)))

(defun +my/recenter-a (&rest _) (recenter))
(dolist (fn '(evil-ex-search-next evil-ex-search-previous
              evil-search-next evil-search-previous
              evil-scroll-down evil-scroll-up))
  (advice-add fn :after #'+my/recenter-a))

(defun +my/paste-no-yank ()
  (interactive)
  (let ((evil-kill-on-visual-paste nil))
    (call-interactively #'evil-paste-before)))

(evil-define-operator +my/delete-no-yank (beg end type)
  (evil-delete beg end type ?_))

(defun +my/join-keep-cursor ()
  (interactive)
  (save-excursion (call-interactively #'evil-join)))

(defun +my/line-diagnostics ()
  (interactive)
  (flycheck-display-errors
   (flycheck-overlay-errors-in (line-beginning-position) (1+ (line-end-position)))))

(defun +my/definition-vsplit ()
  (interactive)
  (evil-window-vsplit)
  (call-interactively #'+lookup/definition))

(defun +my/organize-imports-and-format ()
  (interactive)
  (lsp-organize-imports)
  (run-at-time 0.05 nil #'+format/region-or-buffer))

(defun +my/copy-file-path ()
  (interactive)
  (let ((path (buffer-file-name)))
    (kill-new path)
    (message "file: %s" path)))

(map! :n "j" #'+my/down-wrap-aware
      :n "k" #'+my/up-wrap-aware
      :n "J" #'+my/join-keep-cursor
      :n "-" #'dired-jump

      :n "C-<up>"    (cmd! (evil-window-increase-height 2))
      :n "C-<down>"  (cmd! (evil-window-decrease-height 2))
      :n "C-<left>"  (cmd! (evil-window-decrease-width 2))
      :n "C-<right>" (cmd! (evil-window-increase-width 2))

      :nv "M-j" #'drag-stuff-down
      :nv "M-k" #'drag-stuff-up

      ;; mini.surround
      :n "sa" #'evil-surround-region
      :v "sa" #'evil-surround-region
      :n "sd" #'evil-surround-delete
      :n "sr" #'evil-surround-change

      ;; mini.diff
      :n "]h" #'diff-hl-next-hunk
      :n "[h" #'diff-hl-previous-hunk

      ;; harpoon
      :n "C-h"   #'harpoon-go-to-1
      :n "C-t"   #'harpoon-go-to-2
      :n "C-n"   #'harpoon-go-to-3
      :n "C-s"   #'harpoon-go-to-4
      :n "C-S-p" #'harpoon-go-to-prev
      :n "C-S-n" #'harpoon-go-to-next
      :n "C-e"   #'harpoon-toggle-quick-menu)

;; nvim's leader layout wins over Doom's where they collide
(map! :leader "x" nil "X" nil "q" nil)

(map! :leader
      :desc "Harpoon: add file"         "a"   #'harpoon-add-file
      :desc "Line diagnostics"          "D"   #'+my/line-diagnostics
      :desc "Diagnostic at cursor"      "d"   #'flycheck-display-error-at-point
      :desc "Diagnostic list"           "q"   #'flycheck-list-errors

      :desc "Clear search highlights"   "c h" #'evil-ex-nohighlight
      :desc "Code action"               "c a" #'lsp-execute-code-action
      :desc "Symbols"                   "c s" #'lsp-ui-imenu
      :desc "LSP references"            "c l" #'lsp-ui-peek-find-references
      :desc "Rename symbol"             "r n" #'lsp-rename

      :desc "Next buffer"               "b n" #'next-buffer
      :desc "Previous buffer"           "b p" #'previous-buffer

      :desc "Split vertically"          "s v" #'evil-window-vsplit
      :desc "Split horizontally"        "s h" #'evil-window-split

      :desc "Find files"                "f f" #'+default/find-file-under-here
      :desc "Live grep"                 "f g" #'+default/search-project
      :desc "Buffers"                   "f b" #'consult-buffer
      :desc "Help tags"                 "f h" #'describe-symbol
      :desc "Document diagnostics"      "f x" #'consult-flycheck
      :desc "Workspace diagnostics"     "f X" #'+default/diagnostics
      :desc "LSP references"            "f r" #'+lookup/references
      :desc "LSP type definitions"      "f t" #'+lookup/type-definition
      :desc "LSP document symbols"      "f s" #'consult-lsp-file-symbols
      :desc "LSP workspace symbols"     "f w" #'consult-lsp-symbols
      :desc "LSP implementations"       "f i" #'+lookup/implementations

      :desc "LSP definitions"           "g d" #'+lookup/definition
      :desc "Go to definition"          "g D" #'lsp-find-definition
      :desc "Definition in vsplit"      "g S" #'+my/definition-vsplit

      :desc "Stage hunk"                "h s" #'+vc-gutter/stage-hunk
      :desc "Preview hunk"              "h p" #'diff-hl-show-hunk
      :desc "Git blame"                 "h b" #'magit-blame-addition

      :desc "Next diagnostic"           "n d" #'flycheck-next-error
      :desc "Organize imports + format" "o i" #'+my/organize-imports-and-format

      :desc "Toggle diagnostics"        "t d" #'flycheck-mode

      :desc "Diagnostics"               "x x" #'+default/diagnostics
      :desc "Buffer diagnostics"        "x X" #'flycheck-list-errors
      :desc "Location list"             "x L" #'flycheck-list-errors
      :desc "Quickfix list"             "x Q" #'consult-compile-error
      :desc "Delete without yanking"    "x d" #'+my/delete-no-yank)

(map! :map doom-leader-project-map
      :desc "Copy full file path"  "a" #'+my/copy-file-path
      :desc "Previous diagnostic"  "d" #'flycheck-previous-error)

;; visual SPC p pastes without yanking; normal SPC p stays the project prefix
(define-key doom-leader-map "p"
  `(menu-item "" nil :filter ,(lambda (&optional _)
                                (if (evil-visual-state-p)
                                    #'+my/paste-no-yank
                                  doom-leader-project-map))))

(after! harpoon
  (setq harpoon-separate-by-branch nil
        harpoon-cache-file (concat doom-data-dir "harpoon/")))
