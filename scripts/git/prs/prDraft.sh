#!/usr/bin/env bash
### DOC
# Create a new draft pull request
### DOC
#
# Creates a draft PR using the configured git_pr helpers.
# Draft PRs are visible but marked as work-in-progress.
#
# Usage:
#   dr prDraft
#
### DOC

# shellcheck disable=SC1091,SC2088,SC2164,SC2034,SC2154
set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helper
loadHelpers git/git_pr

main() {
  prNewDraft "$@"
}

main "$@"
