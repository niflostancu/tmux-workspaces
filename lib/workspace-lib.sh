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

# Object properties
_TMUX_WORKDIR=
_TMUX_WORKDIR_WINDOW=

# Sets the working directory to be used for the text workspace object
function @working-dir() {
	_TMUX_WORKDIR="$1"
}

# Tmux object creation routines

function @new-session() {
	local ARGS=(-P -d)
	# append working directory if not specified
	if ! is_option_present "-c" "$@"; then
		[[ -z "$_TMUX_WORKDIR" ]] || ARGS+=(-c "$_TMUX_WORKDIR")
	elif [[ -z "$_TMUX_WORKDIR" ]]; then  # set the default workdir
		local WORKDIR=$(get_option_value "-c" "$@")
		[[ -z "$WORKDIR" ]] || _TMUX_WORKDIR="$WORKDIR"
	fi
	ARGS+=("$@")

	[[ -z "$DEBUG" ]] || echo "tmux new-session ${ARGS[@]}"
	_TMUX_SESSION=$(tmux new-session "${ARGS[@]}")
	_TMUX_WINDOW=$_TMUX_SESSION
	_TMUX_PANE=$_TMUX_WINDOW
}

function @new-window() {
	local ARGS=("${TMUX_WINDOW_ARGS[@]}")
	# append target if not specified
	is_option_present "-t" "$@" || ARGS+=(-t "$_TMUX_SESSION")
	# append working directory if not specified
	if ! is_option_present "-c" "$@" && [[ -n "$_TMUX_WORKDIR" ]]; then
		ARGS+=(-c "$_TMUX_WORKDIR")
	fi
	ARGS+=("$@")

	[[ -z "$DEBUG" ]] || echo "tmux new-window ${ARGS[@]}"
	_TMUX_WINDOW=$(tmux new-window "${ARGS[@]}")
	_TMUX_PANE=$_TMUX_WINDOW
} 

function @split-window() {
	local ARGS=("${TMUX_SPLIT_ARGS[@]}")
	# append target if not specified
	is_option_present "-t" "$@" || ARGS+=(-t "$_TMUX_WINDOW")
	# append working directory if not specified
	if ! is_option_present "-c" "$@" && [[ -n "$_TMUX_WORKDIR" ]]; then
		ARGS+=(-c "$_TMUX_WORKDIR")
	fi
	ARGS+=("$@")

	[[ -z "$DEBUG" ]] || echo "tmux split-window ${ARGS[@]}"
	_TMUX_PANE=$(tmux split-window "${ARGS[@]}")
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

