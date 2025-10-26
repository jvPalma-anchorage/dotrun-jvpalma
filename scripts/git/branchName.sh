#!/usr/bin/env bash
### DOC
# Display current git branch name with formatting
### DOC
#
# Prints the current git branch name with color-coded formatting.
# Uses cyan for 'co' command and yellow for the branch name.
#
# Usage:
#   dr branchName
#
### DOC

# shellcheck disable=SC1091,SC2088,SC2164,SC2034,SC2154

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helper
loadHelpers git/git

main() { #    Git -> Accept all INCOMING changes and continue rebase
  echo ""
  echo -e "\t ${CYAN} co ${YELLOW} $(git_current_branch)"
  echo ""
}

main "$@"
