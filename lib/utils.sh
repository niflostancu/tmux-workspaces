#!/usr/bin/env bash
# Helper functions for the plugin

# colored defs
_ANSI_ESCAPE=$'\033'
_ANSI_RESET="${_ANSI_ESCAPE}[0m"
declare -A _ANSI_COLORS=(
	[black]="30"  [red]="31"
	[green]="32"  [yellow]="33"
	[blue]="34"   [purple]="35"
	[cyan]="36"   [white]="37"
)

# colored console printing
function pcolor() {
	local COLORDEF="$1"; shift
	local TEXT="$*"
	local RESET=
	local BOLD=0  # not bold
	local ANSI_COLOR=
	if [[ "$COLORDEF" == *'$'* ]]; then RESET="$_ANSI_RESET"; COLORDEF="${COLORDEF/$/}"; fi
	if [[ "$COLORDEF" == *'*'* ]]; then BOLD=1; COLORDEF="${COLORDEF%\*}"; fi
	[[ -z "$COLORDEF" ]] || ANSI_COLOR="${_ANSI_ESCAPE}[${BOLD};${_ANSI_COLORS[$COLORDEF]}m"
	echo "$ANSI_COLOR$TEXT$RESET"
}

# returns the value of a tmux option or a default one, if not defined
# takes roughly the same arguments as tmux's show-options command (with an
# exception: -s flag is for session here, server options are not used)
get_tmux_option() {
	local ARGS=()
	local GLOBAL=1
	local OPTION=
	local DEFAULT=
	while [[ "$#" -gt 0 ]]; do
		# reminder: -s stands for session options
		if [[ "$1" == "-s" ]]; then
			GLOBAL=;
		elif [[ "$1" == "-"[gw] ]]; then
			GLOBAL=; ARGS+=("$1")
		elif [[ "$1" == "-t" ]]; then
			ARGS+=(-t "$2"); shift
		else
			OPTION="$1"; DEFAULT="$2"
			break
		fi
		shift
	done
	local value=$(tmux show-option "${ARGS[@]}" -qv "$OPTION")
	if [[ -z "$value" ]]; then
		echo "$DEFAULT"
	else
		echo "$value"
	fi
}

# infers the value of a tmux option, trying window, session and global (in this
# order); same arguments as get_tmux_option, except the missing scope argument
# (since they are all tried).
infer_tmux_option() {
	# remove the default value from $@ (use empty string so -n will work)
	local default="${@: -1}"
	local A=("${@:1:$#-1}")
	local value=$(get_tmux_option -w "${A[@]}")
	[[ -n "$value" ]] || value=$(get_tmux_option -s "${A[@]}")
	[[ -n "$value" ]] || value=$(get_tmux_option -g "${A[@]}")
	echo "${value:-$default}"
}

# adds a directory to tmux's global/session PATH environment variable
# use -g for global, defaults to setting the session variable
tmux_add_to_path() {
	local SPECIFIERS=()
	local VALUE=
	while [[ "$#" -gt 0 ]]; do
		if [[ "$1" == "-"[gru] ]]; then
			SPECIFIERS+=("$1")
		elif [[ "$1" == "-t" ]]; then
			SPECIFIERS+=(-t "$2"); shift
		else
			VALUE="$1"
			break
		fi
		shift
	done
	local CURRENT_PATH=$PATH
	if [[ ":$CURRENT_PATH:" != *:"$VALUE":* ]]; then
		# add it
		tmux set-environment "${SPECIFIERS[@]}" PATH "$VALUE:$CURRENT_PATH"
	fi
}

# Argument parsing routines

# Returns whether the specified option flag (e.g., -t) is set.
# Syntax: `is_option_present OPTION ARGS...`
function is_option_present() {
	local OPTION="$1"; shift
	for opt in "$@"; do
		[[ "$opt" != "$OPTION" ]] || return 0
	done
	return 1
}

# Returns the value of a option's argument
# Syntax: `get_option_value OPTION ARGS...`
function get_option_value() {
	local OPTION="$1"; shift
	while [[ "$#" -gt 0 ]]; do
		if [[ "$1" == "$OPTION" ]]; then
			echo "$2"; return 0
		fi
		shift
	done
}

