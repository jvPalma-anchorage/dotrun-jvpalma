#!/usr/bin/env bash
### DOC
# Smart tmux session manager
### DOC
#
# Intelligently manages tmux sessions:
# - With no arguments: attaches to existing session or creates default
# - With session name: attaches to named session or creates if doesn't exist
#
# Usage:
#   dr tm [session-name]
#
# Arguments:
#   session-name         Optional name for tmux session
#
# Examples:
#   dr tm                # Attach to existing or create default session
#   dr tm work           # Attach to or create "work" session
#   dr tm project        # Attach to or create "project" session
#
### DOC
set -euo pipefail

main() {
  local session_name="${1-}"

  if [ -z "$session_name" ]; then
    if tmux has-session 2>/dev/null; then
      tmux attach-session
    else
      tmux
    fi
  else
    if tmux has-session -t "$session_name" 2>/dev/null; then
      tmux attach-session -t "$session_name"
    else
      tmux new-session -s "$session_name"
    fi
  fi
}

main "$@"
