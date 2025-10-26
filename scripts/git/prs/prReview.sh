#!/usr/bin/env bash
### DOC
# Perform AI code review on a pull request
### DOC
#
# Checks out master, fetches latest changes, and uses Claude AI to perform
# a comprehensive code review of the specified PR against origin/master.
#
# Usage:
#   dr prReview 123
#
# Requirements:
# - Must be run from within a git repository
# - Claude CLI must be installed and configured
#
### DOC

# shellcheck disable=SC1091,SC2088,SC2164,SC2034,SC2154,SC2076

set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helper
loadHelpers global/logging
loadHelpers git/git_pr

ensure_git_repo

main() {
  local pr_number=$1

  # Get current git repository root (agnostic to any system)
  local repo_root
  if ! repo_root=$(git rev-parse --show-toplevel 2>/dev/null); then
    log_error "Not inside a git repository"
    exit 1
  fi

  cd "$repo_root" || exit 1
  git checkout master >/dev/null 2>&1 && log_success "Checkout to master"
  dr git/commits/fetch
  claude --dangerously-skip-permissions "/review Do an full code review to PR #$pr_number"
}

main "$@"
