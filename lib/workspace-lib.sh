#!/usr/bin/env bash
# Tmux workspace library - routines available inside scripts.

# stores the last session / window / pane defined by the open functions
_TMUX_SESSION=
_TMUX_WINDOW=
_TMUX_PANE=

# set to non-null to log the tmux functions executed
DEBUG=

# extra arguments injected to window / pane creation routines
TMUX_WINDOW_ARGS=(-d -P -F "#{session_name}:#{window_index}")
TMUX_SPLIT_ARGS=(-P -F "#{session_name}:#{window_index}")

# Tmux object creation routines

function @new-session() {
	[[ -z "$DEBUG" ]] || echo "tmux new-session -P -d $@"
	_TMUX_SESSION=$(tmux new-session -P -d "$@")
	_TMUX_WINDOW=$_TMUX_SESSION
	_TMUX_PANE=$_TMUX_WINDOW
}

function @new-window() {
	[[ -z "$DEBUG" ]] || echo "new-window -t $_TMUX_SESSION ${TMUX_WINDOW_ARGS[@]} $@"
	_TMUX_WINDOW=$(tmux new-window -t "$_TMUX_SESSION" "${TMUX_WINDOW_ARGS[@]}" "$@")
	_TMUX_PANE=$_TMUX_WINDOW
} 

function @split-window() {
	[[ -z "$DEBUG" ]] || echo "tmux split-window -t $_TMUX_WINDOW ${TMUX_SPLIT_ARGS[@]} $@"
	_TMUX_PANE=$(tmux split-window -t "$_TMUX_WINDOW" "${TMUX_SPLIT_ARGS[@]}" "$@")
}


# Other tmux wrapper routines

function @send-keys() {
	[[ -z "$DEBUG" ]] || echo "tmux send-keys -t $_TMUX_PANE $@"
	tmux send-keys -t "$_TMUX_PANE" "$@"
}

function @select-window() {
	[[ -z "$DEBUG" ]] || echo "tmux select-window $@"
	tmux select-window "$@"
}

function @set-option() {
	# determine option's target (window / session / pane)
	local _ARGS=(-t "$_TMUX_SESSION")
	for opt in "$@"; do
		if [[ "$opt" == "-g" || "$opt" == "-t" ]]; then
			# no target required
			ARGS=(); break;
		elif [[ "$opt" == "-w" ]]; then
			ARGS=(-t "$_TMUX_WINDOW"); break;
		elif [[ "$opt" == "-p" ]]; then
			ARGS=(-t "$_TMUX_PANE"); break;
		fi # defaults to session target
	done
	[[ -z "$DEBUG" ]] || echo "tmux set-option ${_ARGS[@]} $@"
	tmux set-option "${_ARGS[@]}" "$@"
}

function @temporary-option() {
	local SLEEP="$1"; shift
	local VALUE="${@: -1}";
	local _SAVED_OPTION=$(tmux show-option -v "${@:1:$#-1}")
	@set-option "${@:1:$#-1}" off
	{ sleep "$SLEEP"; @set-option "${@:1:$#-1}" "$_SAVED_OPTION"; }&
}

# sets an environment variable
# sets either a global (-g) or session (default) value
function @set-environment() {
	local ARGS=("$@")
	if _check_needs_target "$@"; then ARGS=(-t "$_TMUX_SESSION" "${ARGS[@]}"); fi
	tmux set-environment "${ARGS[@]}"
}

# add a path to $PATH
# works as either global (-g) or session (default) path variable
function @add-to-path() {
	local ARGS=("$@")
	if _check_needs_target "$@"; then ARGS+=(-t "$_TMUX_SESSION"); fi
	tmux_add_to_path "${ARGS[@]}"
}

# internal functions

# returns 0 if the command needs the implicit target (-t) argument
# (for most tmux functions, no "-g" or "-t" given)
function _check_needs_target() {
	local GLOBAL=
	for opt in "$@"; do
		if [[ "$opt" == "-g" ]]; then return 1; fi
		if [[ "$opt" == "-t" ]]; then return 1; fi
	done
	return 0
}

