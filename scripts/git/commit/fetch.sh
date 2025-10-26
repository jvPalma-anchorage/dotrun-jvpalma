#!/usr/bin/env bash
### DOC
# Fetch master and personal branches from origin
### DOC
#
# Fetches multiple git references from origin including master branch refs,
# all jvPalma branches, and pulls latest changes. Provides success logging
# for each operation.
#
# Usage:
#   dr fetch
#
# Examples:
#   dr fetch             # Fetch master and jvPalma branches
#
# Requirements:
#   - Git repository with origin remote
#   - dr logging helpers
#
### DOC

# shellcheck disable=SC1091,SC2088,SC2164,SC2034,SC2154
set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helper
# loadHelpers global/colors
loadHelpers global/logging
# loadHelpers git

main() {
  # Get GitHub username from git config to fetch user-specific branches
  local github_user
  github_user=$(git config --get user.name 2>/dev/null || echo "")
  github_user=${GIT_USERNAME:-$github_user}

  git fetch origin "refs/heads/master:refs/remotes/origin/master" >/dev/null 2>&1 && log_success "Fetched master refs"

  # Fetch user-specific branches if username is configured
  if [[ -n "$github_user" ]]; then
    git fetch origin "refs/heads/${github_user}/*:refs/remotes/origin/${github_user}/*" >/dev/null 2>&1 && log_success "Fetched ${github_user} branches"
  fi

  git fetch origin master >/dev/null 2>&1 && log_success "Fetched master branch"
  git pull >/dev/null 2>&1 && log_success "Pulled latest changes"
}

main "$@"
