#!/usr/bin/env bash
### DOC
# Update master branch and return to original branch
### DOC
#
# Workflow:
# 1. Checks if in a git repository
# 2. Stores current branch name
# 3. Checks out master branch
# 4. Fetches latest changes from origin/master
# 5. Pulls latest changes
# 6. Stays on master if already there, otherwise ready to switch back
#
# Usage:
#   dr master
#
# Requirements:
#   - Git repository with origin remote
#   - dr git and color helpers
#
### DOC

# shellcheck disable=SC1091,SC2088,SC2164,SC2034,SC2154
set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helper
loadHelpers global/colors
loadHelpers global/logging
loadHelpers git

checkoutToMaster() {
  # Checkout the master branch
  log_info "Checking out master branch..."
  if ! git checkout master >/dev/null 2>&1; then
    log_error "Failed to checkout master"
    exit 1
  fi
}

fetchMaster() {
  # Pull the latest changes from origin/master
  log_info "Fetching latest changes from master..."
  if ! git fetch origin master >/dev/null 2>&1; then
    log_error "Failed to fetch latest changes from origin/master"
    exit 1
  fi
}

pullMaster() {
  # Pull the latest changes from origin/master
  log_info "Pulling latest changes from master..."
  if ! git pull origin master >/dev/null 2>&1; then
    log_error "Failed to pull latest changes from origin/master"
    exit 1
  fi
}

main() {
  clear
  # Check if we're in a git repository
  ensure_git_repo

  # Store current branch name
  current_branch=$(git_current_branch)
  exitIfNoBranchName

  log_info "${YELLOW}🧬 Update ${MAGENTA}\`master\`${YELLOW} Branch${NC}"
  log_info "\t${BLUE}💾 Current branch: ${CYAN}\`$current_branch\`${NC}"

  # Update master branch
  checkoutToMaster

  # Pull the latest changes from origin/master
  fetchMaster

  pullMaster

  log_success "${GREEN}✅ Successfully updated ${MAGENTA}\`master\`${NC}\n------------------------------------------------------------------------"

  # Prevent running on master branch
  if [ "$current_branch" = "master" ]; then
    exit 0
  fi
}

main "$@"
