;;; lisp/terminal.el -*- lexical-binding: t; -*-

(after! vterm
  (set-popup-rule! "^\\*doom:vterm-popup" :size 0.8 :vslot -4 :select t :quit nil :ttl 0)
  (setq vterm-kill-buffer-on-exit t
        vterm-shell (or (getenv "SHELL") vterm-shell))
  (map! :map vterm-mode-map
        :i "<escape>" #'evil-normal-state
        :ni "C-q" #'+vterm/toggle))

(add-hook 'vterm-mode-hook (lambda () (display-line-numbers-mode -1)))

(map! :leader :desc "Toggle floating terminal" "t t" #'+vterm/toggle)
