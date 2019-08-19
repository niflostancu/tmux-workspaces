# Tmux Workspaces plugin

This project aims to bring a pleasant and complete workspace workflow plugin for
tmux.
It provides a framework for writing scripts to bootstrap your tmux sessions with
the desired windows / panes / commands and tools to easily manage them.

<p align="center">
<img src="/docs/screenshots/fuzzy_selector.png?raw=true" alt="Fuzzy Selector"
  title="Fuzzy Selector" width="300">
<img src="/docs/screenshots/workspace_script.png?raw=true" alt="Workspace
  Script" title="Workspace Script " width="300">
</p>

Features:

- Framework for writing workspace scripts;
- fast session creation, much faster than
  [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect<Paste>) and
  [tmuxp](https://github.com/tmux-python/tmuxp/)
- fuzzy selector;
- utility scripts (e.g., kill session and switch to previous);


## Installation

### Using Tmux Plugin Manager (recommended)

It is recommended that you use [tpm](https://github.com/tmux-plugins/tpm/) to
manage your tmux plugins:

```tmux
set -g @plugin 'niflostancu/tmux-workspaces'
```

Then reload the tmux config: `$ tmux source-file ~/.tmux.conf` and use the
install bindings (`<prefix> + I`).

### Manually

If you wish do it yourself, download the repository:
```sh
git clone https://github.com/niflostancu/tmux-workspaces ~/clone/path
```

Then load the script inside your `tmux.conf`:
```txt
run-shell ~/clone/path/workspaces.tmux
```

## Configuration

Here's a sample configuration to get you started:

```txt
# this is the default location for session scripts
set-option -g @workspaces-dir "$XDG_DATA_HOME/tmux/sessions"

# for tmux >=2.9, you can create aliases!
# example calling the session script using the <prefix> + :skill command:
set -g command-alias[10] skill='run-shell "#{@workspaces-srcdir}/scripts/kill-session.sh"'

# Bind fuzzy search on <prefix>+Ctrl+j:
bind C-j run-shell "#{@workspaces-srcdir}/scripts/fuzzy-workspaces.sh"
```

Proceed to the **Scripting** section for instructions and example scripts.

## Scripting

Workspaces are defined as bash scripts using special tmux object manipulation
routines. Example session:

```sh
SESSION="tmux-plugins"
DIR=~/Projects/tmux-plugins

# disable activity monitoring for 5 seconds while the session is created
@temporary-option 5 -wg monitor-activity off

# create the session
@new-session -s "$SESSION" -n "nvim" -c "$DIR"
# tmux options can be set only for the current session
@set-option -s "status-left" "#h | #(curl icanhazip.com) | [#S]"
# open neovim on the first pane
@send-keys "nvim" ENTER

# two other windows
@new-window -n "test" -c "$DIR/per-window-dir"
# note: the target attribute (-t) is automatically detected when not set
@split-pane -v
# (this splits the last window created, "test")

# at the end, select the first window
@select-window -t "$SESSION:1"
```

Check the [workspace scripting library's](lib/workspace-lib.sh) code for
the available functions.

