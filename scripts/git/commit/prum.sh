#!/usr/bin/env bash
### DOC
# Pull from master and force-push current branch
### DOC
#
# Workflow:
# 1. Pulls latest changes from origin/master
# 2. Force pushes current branch with lease protection
#
# Usage:
#   dr prum
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

  if ! git pull origin master >/dev/null 2>&1; then
    log_error "Failed to pull master"
    exit 1
  fi
  log_success "pull from master"

  if ! HUMAN_VERIFIED=true git push --force-with-lease >/dev/null 2>&1; then
    log_error "Failed to push changes"
    exit 1
  fi
  log_success "push'd changes"
}

main "$@"
