#!/usr/bin/env bash
# Shows a list of available workspaces using a fuzzy tool (fzf by default)

set -e
shopt -s extglob
# tmux run-shell doesn't display stderr, so redirect it
exec 2>&1

SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"

source "$SRC_DIR/lib/utils.sh"
source "$SRC_DIR/lib/workspaces.sh"

# what fuzzy finder tool (and args) to use?
FUZZY_TOOL=$(get_tmux_option "@workspaces-fuzzytool" "fzf-tmux -- --ansi --reverse")

function fuzzy_workspace_action() {
	local WORKSPACE_NAME="$1"
	# trim flags / whitespace
	WORKSPACE_NAME=${WORKSPACE_NAME##+([#* ])}
	WORKSPACE_NAME=${WORKSPACE_NAME%%+([#* ])}
	[[ -n "$WORKSPACE_NAME" ]] || return 0

	workspace_switch "$WORKSPACE_NAME"
}

function union_workspaces_session() {
	local CURRENT_SESSION=$(tmux display-message -p '#{session_name}')
	local LAST_SESSION=$(tmux display-message -p '#{client_last_session}')
	local OPEN_SESSIONS=$(tmux list-sessions -F '#S' | sort)
	local FLAGS=
	# first, output the open sessions with colored text and marker
	echo "$OPEN_SESSIONS" | while read -d $'\n' line; do
		FLAGS=" "
		if [[ "$line" == "$CURRENT_SESSION" ]]; then
			FLAGS="$(pcolor '*green')*"
		elif [[ "$line" == "$LAST_SESSION" ]]; then
			FLAGS="$(pcolor '*cyan')#"
		fi
		echo "$FLAGS $(pcolor 'cyan')$line$(pcolor '$')"
	done
	# next, output all other sessions found in files
	FLAGS=" "
	comm -13 <(echo "$OPEN_SESSIONS") <(workspaces_list | sort -u) | \
		sed "s/^/$FLAGS /; s/$/ /"
}

fuzzy_workspace_action "$(union_workspaces_session | sort -u | $FUZZY_TOOL )" 

