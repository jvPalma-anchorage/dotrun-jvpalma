#!/usr/bin/env bash
### DOC
# Convert draft PR to ready and add reviewers/labels
### DOC
#
# Marks a draft PR as ready for review, then automatically adds configured
# labels and reviewers. Two-step process: convert draft to open, then apply
# ready-state metadata.
#
# Usage:
#   dr prReady 1234         # Mark PR #1234 as ready for review
#
### DOC

# shellcheck disable=SC1091,SC2088,SC2164,SC2034,SC2154

set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helper
loadHelpers git/git_pr
# loads $FRONTEND_TEAM
# loads $LABELS_READY_ADD

main() {
  if [ "$#" -ge 1 ]; then
    PR_NUMBER="$1"
  else
    echo "Please provide a PR Number"
    return 0
  fi

  prDraftToOpen "$PR_NUMBER"
  prReadyAddLabelsAndReviewers "$PR_NUMBER"
}

main "$@"
