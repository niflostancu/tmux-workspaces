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
get_tmux_option() {
	local option="$1"
	local default_value="$2"
	local option_value=$(tmux show-option -gqv "$option")
	if [ -z "$option_value" ]; then
		echo "$default_value"
	else
		echo "$option_value"
	fi
}


