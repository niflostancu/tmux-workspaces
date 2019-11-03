#!/usr/bin/env bash
# Routines for loading / managing workspaces

# infer the path to the workspaces dir
if [[ -z "$TMUX_WORKSPACES_DIR" ]]; then
	XDG_DATA_HOME=${XDG_DATA_HOME:-~/.local/share}
	TMUX_WORKSPACES_DIR=$(get_tmux_option "@workspaces-dir" "${XDG_DATA_HOME}/tmux/sessions")
fi

# opens a tmux workspace (sourcing it if not already loaded)
function workspace_switch() {
	local WORKSPACE_NAME="$1"
	if ! tmux has-session -t="$WORKSPACE_NAME" 2>/dev/null; then
		workspace_load "$WORKSPACE_NAME"
	fi

	# if inside tmux, just switch the client to the new workspace
	if [[ -z "$TMUX" ]]; then
		tmux attach -t "$WORKSPACE_NAME"
	else
		tmux switch-client -t "$WORKSPACE_NAME"
	fi
}

function workspace_load() {
	local WORKSPACE_NAME="$1"
	# load the workspace lib
	source "$SRC_DIR/lib/workspace-lib.sh"
	# load the workspace script
	source "$TMUX_WORKSPACES_DIR/$WORKSPACE_NAME.tmux"
}

# lists all available workspace files (without the extension)
function workspaces_list() {
	find "${TMUX_WORKSPACES_DIR}" -name '*.tmux' -printf '%f\n' \
			| sed 's/\.tmux$//'
}

