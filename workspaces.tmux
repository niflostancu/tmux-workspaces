#!/usr/bin/env bash
# Initializes the Tmux Workspaces plugin

set -e
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SRC_DIR/lib/utils.sh"

# store the path to the source dir (used by scripts)
tmux set -g "@workspaces-srcdir" "$SRC_DIR"

# also add bin/ to PATH for tmux-workspace script to be available
tmux_add_to_path -g "$SRC_DIR/bin"

