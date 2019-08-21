#!/usr/bin/env bash
# Script to capture a pane's contents to file
# Automatically called by tmux hooks set up by the plugin

set -e
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

. "${SRC_DIR}/lib/utils.sh"
. "${SRC_DIR}/lib/capture-pane.sh"

# received arguments: (the address of the pane to save)
TMUX_SESSION_NAME="$1"
TMUX_WINDOW_ID="$2"
TMUX_PANE_ID="$3"

if [[ "$TMUX_SESSION_NAME" == '!' ]]; then
	# autodetect the address of the last session
	TMUX_SESSION_NAME=$(last_client_session)
	TMUX_WINDOW_ID=$(last_session_window "$TMUX_SESSION_NAME") || exit 0
	TMUX_PANE_ID=$(last_session_pane "$TMUX_SESSION_NAME") || exit 0
fi

# noop if any pane ID component could not be established
[[ -z "$TMUX_SESSION_NAME" || -z "$TMUX_WINDOW_ID" || -z "$TMUX_PANE_ID" ]] && exit 0

TARGET_PANE="$TMUX_SESSION_NAME:$TMUX_WINDOW_ID.$TMUX_PANE_ID"

# load the capture pane options
capture_pane_options "$TARGET_PANE"
[[ "$CAPTURE_ENABLED" == "1" ]] || exit 0

mkdir -p "$TMUX_CAPTURE_PATH" || {
	echo "Unable to create capture path: $CAPTURE_PATH" >&2
	exit 1
}

TARGET_FILE="$TMUX_CAPTURE_PATH/pane-${TARGET_PANE}"
CONTENTS=$(tmux capture-pane -t "$TARGET_PANE" -epJ -S -)
OLD_CONTENTS_FOR_DIFF=$(cat "$TARGET_FILE" 2>/dev/null | strip_ansi || true)

DIFF_COUNT=$(diff -y --suppress-common-lines <(echo -n "$CONTENTS" | strip_ansi) <(echo -n "$OLD_CONTENTS_FOR_DIFF") \
	| paste | wc -l)

# tmux display "$TARGET_PANE COUNT: $DIFF_COUNT"

if [[ -n "$TMUX_CAPTURE_DEBUG" ]]; then
	diff -y --suppress-common-lines <(echo -n "$CONTENTS" | strip_ansi) <(cat "$TARGET_FILE" | strip_ansi) \
		> "$TARGET_FILE.d.txt" || true
fi

# difference threshold to prevent storing empty prompts (when a pane is left unused)
if [[ "$DIFF_COUNT" -gt 5 ]]; then
	if [[ -n "$CAPTURE_STRIP_ANSI" ]]; then
		echo "$CONTENTS" | strip_ansi > "$TARGET_FILE"
	else
		echo "$CONTENTS" > "$TARGET_FILE"
	fi
fi

