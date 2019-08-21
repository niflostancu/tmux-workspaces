#!/usr/bin/env bash
# Common functions for the capture pane feature

# infer the path storing the captured panes
if [[ -z "$TMUX_CAPTURE_PATH" ]]; then
	XDG_DATA_HOME=${XDG_DATA_HOME:-~/.local/share}
	TMUX_CAPTURE_PATH=$(get_tmux_option "@capture-pane-path" "${XDG_DATA_HOME}/tmux/capture-pane")
fi

# infers the capture pane option variables
function capture_pane_options() {
	local TARGET="$1"
	# note: these are global variables
	CAPTURE_STRIP_ANSI=$(get_tmux_option -s -t "$TARGET" "@capture-pane-strip-ansi" "")
	if [[ -z "$CAPTURE_STRIP_ANSI" ]]; then
		CAPTURE_STRIP_ANSI=$(get_tmux_option -g -t "$TARGET" "@capture-pane-strip-ansi" "")
	fi
	CAPTURE_ENABLED=$(get_tmux_option -s -t "$TARGET" "@capture-pane-enable" "")
	if [[ -z "$CAPTURE_ENABLED" ]]; then
		CAPTURE_ENABLED=$(get_tmux_option -g -t "$TARGET" "@capture-pane-enable" "0")
	fi
}

# converts any Tmux pane ID (e.g. %1) to a normalized target format
function normalize_pane_id() {
	local ID="$1"
	tmux display -t "$ID" -p "#{session_name}:#{window_index}.#{pane_index}"
}

# returns the full path to the capture file for a given pane
function get_capture_file() {
	local TARGET_PANE=$(normalize_pane_id "$1")
	echo "$TMUX_CAPTURE_PATH/pane-${TARGET_PANE}"
}

# strips ANSI escape sequences (use with pipe)
function strip_ansi() {
	sed "s,\x1B\[[0-9;]*[a-zA-Z],,g"
}

# tmux pane address retrieval routines
last_client_session() {
	tmux display -p "#{client_last_session}"
}

last_session_window() {
	tmux display -p -t "$1:" "#{window_index}"
}

last_session_pane() {
	tmux display -p -t "$1:" "#{pane_index}"
}
