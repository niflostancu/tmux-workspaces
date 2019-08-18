#!/bin/bash
# Utility script that kills the current session while selecting the previous one

tmux switch-client -l
tmux kill-session -t "$(tmux display-message -p "#S")"

