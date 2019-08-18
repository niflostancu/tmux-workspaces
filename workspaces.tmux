#!/usr/bin/env bash
# Initializes the Tmux Workspaces plugin

SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# store the path to the source dir (used by scripts)
tmux set -g "@workspaces-srcdir" "$SRC_DIR"

# also add bin/ to PATH for tmux-workspace script to be available
CURRENT_PATH=$(tmux show-environment -g PATH | sed 's:^.*=::')
tmux set-environment -g PATH "$SRC_DIR/bin:$CURRENT_PATH"

