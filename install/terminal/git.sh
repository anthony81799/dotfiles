#!/usr/bin/env bash
# ===============================================
# Git installer
# ===============================================
set -euo pipefail
IFS=$'\n\t'

source "${HOME}/install/lib.sh"

init_log "${LOG_DIR}/git-install.log"

ensure_gum

banner "Configuring Git"
GIT_CONFIG_FILE="${XDG_CONFIG_HOME}/git/config"
GIT_NAME=$(gum input --placeholder "Enter your Git Name (e.g., Jane Doe)")
GIT_EMAIL=$(gum input --placeholder "Enter your Git Email (e.g., jane@example.com)")

spinner "Configuring Git..."
mkdir -p "$(dirname "${GIT_CONFIG_FILE}")"

tee "$GIT_CONFIG_FILE" >/dev/null <<EOF
[user]
    name = ${GIT_NAME}
    email = ${GIT_EMAIL}

[commit]
    verbose = true  # add more context to commit messages

[core]
    autocrlf = input  # keep newlines as in input
    compression = 9  # trade cpu for network
    fsync = none
    whitespace = error  # treat incorrect whitespace as errors
    preloadindex = true  # preload index for faster status
	pager = delta

[advice]  # disable advice messages
    addEmptyPathspec = false
    pushNonFastForward = false
    statusHints = false

[blame]
    coloring = highlightRecent
    date = relative

[diff]
    context = 3  # less context in diffs
    renames = copies  # detect copies as renames in diffs
    interHunkContext = 10  # merge near hunks in diffs

[log]
    abbrevCommit = true  # short commits

[status]
    branch = true
    short = true
    showStash = true
    showUntrackedFiles = all  # show individual untracked files

[pager]
    branch = false  # no need to use pager for git branch
    tag = false

[push]
    autoSetupRemote = true  # easier to push new branches
    default = current  # push only current branch by default
    followTags = true  # push also tags

[pull]
    rebase = true
    default = current

[submodule]
    fetchJobs = 16

[rebase]
    autoStash = true
    missingCommitsCheck = warn  # warn if rebasing with missing commits

[merge]
    conflictStyle = zdiff3

[pack]
    threads = 0  # use all available threads
    windowMemory = 1g  # use 1g of memory for pack window
    packSizeLimit = 1g  # max size of a packfile

# Integrity
[transfer]
    fsckObjects = true

[receive]
    fsckObjects = true

[fetch]
    fsckObjects = true

[branch]
    sort = -committerdate

[tag]
    sort = -taggerdate

[interactive]
    diffFilter = delta --color-only
    singlekey = true

[delta]
	syntax-theme = gruvbox-dark
    dark = true
	true-color = always
    navigate = true
	side-by-side = true
	line-numbers = true
	whitespace-error-style = highlight
	minus-style = syntax # use syntax highlighting for deletions
	plus-style = syntax # use syntax highlighting for additions
	hyperlinks = true
	diff-so-fancy = true
EOF

finish "Git configured successfully!"
