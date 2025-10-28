#!/usr/bin/env bash
### DOC
# Add all changes, commit with message, and push
### DOC
#
# Automates the workflow of staging all changes, creating a commit with
# a provided message, and pushing to remote with force-with-lease.
#
# Usage:
#   dr addCommitAndPush <message>
#
# Arguments:
#   message    Commit message (required)
#
# Examples:
#   dr addCommitAndPush "Fix bug in parser"
#   dr addCommitAndPush "Add new feature"
#
# Operations:
# 1. git add -A                       Stage all changes
# 2. git commit -m "<message>"        Create commit with message
# 3. git push --force-with-lease      Safe force push
#
# Warning: Uses force push! Ensure you're on the correct branch.
#
### DOC

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

loadHelpers global/logging

main() {

  if [ ! "$#" -ge 1 ]; then
    log_error "Provide a commit Message"
    exit 1
  fi

  HUMAN_VERIFIED=true git add -A
  HUMAN_VERIFIED=true git commit -m "$1"
  HUMAN_VERIFIED=true git push --force-with-lease

}

main "$@"
