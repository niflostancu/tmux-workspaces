#!/usr/bin/env bash
# Initializes the Tmux Workspaces plugin

set -e
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SRC_DIR/lib/utils.sh"

# store the path to the source dir (used by scripts)
tmux set -g "@workspaces-srcdir" "$SRC_DIR"

# also add bin/ to PATH for tmux-workspace script to be available
tmux_add_to_path -g "$SRC_DIR/bin"

# initialize the capture pane plugin (if enabled)
source "$SRC_DIR/lib/capture-pane.sh"

# set environment var with the restore command
tmux set-environment -g "TMUX_PANE_RESTORE_CMD" "$SRC_DIR/scripts/restore-pane.sh"

# setup pane capturing hooks (on change events)
TMUX_SAVE_CMD="'$SRC_DIR/scripts/save-pane.sh'"
TMUX_SAVE_ARGS="#{session_name} #{window_index} #{pane_index}"
tmux set-hook -g window-pane-changed "run-shell -b -t '{last}' '$TMUX_SAVE_CMD $TMUX_SAVE_ARGS'"
tmux set-hook -g session-window-changed "run-shell -b -t '{last}.' '$TMUX_SAVE_CMD $TMUX_SAVE_ARGS'"
tmux set-hook -g client-session-changed "run-shell -b '$TMUX_SAVE_CMD \"!\"'"
tmux set-hook -g client-detached "run-shell -b '$TMUX_SAVE_CMD $TMUX_SAVE_ARGS'"

