#!/usr/bin/env bash
# Restores the contents of the current pane, if any

set -e
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}/")/.." && pwd)"

. "${SRC_DIR}/lib/utils.sh"
. "${SRC_DIR}/lib/capture-pane.sh"

# Tmux automatically sets this environment variable
[[ -n "$TMUX_PANE" ]] || exit 0

# TMUX_PANE contains the global ID of the pane
TARGET_FILE=$(get_capture_file "$TMUX_PANE")

if [[ -f "$TARGET_FILE" ]]; then
	cat "$TARGET_FILE"
fi

