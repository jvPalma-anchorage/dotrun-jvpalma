#!/usr/bin/env bash
### DOC
# Clean up PR reviewers and labels to match allowed lists
### DOC
#
# Audits a PR's reviewers and labels against configured allowed lists.
# Removes reviewers not in FRONTEND_TEAM, removes non-allowed labels,
# and adds any missing required labels from LABELS_READY_ADD.
#
# Usage:
#   dr prFix <pr-number> # Clean reviewers and labels for PR #<pr-number>
#
# Configuration:
# - Reads $FRONTEND_TEAM from git_pr helpers
# - Reads $LABELS_READY_ADD from git_pr helpers
#
### DOC

# shellcheck disable=SC1091,SC2088,SC2164,SC2034,SC2154,SC2076

set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helper
loadHelpers git/git_pr
# loads $FRONTEND_TEAM
# loads $LABELS_READY_ADD

main() {
  local pr_number=$1

  local CURRENT_REVIEWERS=''
  local REVIEWERS_TO_REMOVE=''

  local CURRENT_LABELS=''
  local LABELS_TO_REMOVE=''
  local LABELS_TO_ADD=""
  local FRONTEND_TEAM="${FRONTEND_TEAM:-}"
  local LABELS_READY_ADD="${LABELS_READY_ADD:-}"

  # Clean reviewers
  if [[ -n "$FRONTEND_TEAM" ]]; then
    CURRENT_REVIEWERS=$(gh pr view "$pr_number" --json reviewRequests --jq '.reviewRequests[].login' | tr '\n' ',')
    IFS=',' read -ra currentRev <<<"$CURRENT_REVIEWERS"
    IFS=',' read -ra allowedRev <<<"$FRONTEND_TEAM"

    local REVIEWERS_TO_REMOVE=""
    for reviewer in "${currentRev[@]}"; do
      if [[ ! " ${allowedRev[*]} " =~ " ${reviewer} " ]]; then
        REVIEWERS_TO_REMOVE="${REVIEWERS_TO_REMOVE}${reviewer},"
      fi
    done

    if [[ -n "$REVIEWERS_TO_REMOVE" ]]; then
      REVIEWERS_TO_REMOVE=${REVIEWERS_TO_REMOVE%,}
      gh pr edit "$pr_number" --remove-reviewer "$REVIEWERS_TO_REMOVE"
    fi
  fi

  # Clean labels and ensure allowed labels are present
  if [[ -n "$LABELS_READY_ADD" ]]; then
    CURRENT_LABELS=$(gh pr view "$pr_number" --json labels --jq '.labels[].name' | tr '\n' ',')
    IFS=',' read -ra currentLab <<<"$CURRENT_LABELS"
    IFS=',' read -ra allowedLab <<<"$LABELS_READY_ADD"

    # Remove labels that are not in the allowed list
    for label in "${currentLab[@]}"; do
      if [[ ! " ${allowedLab[*]} " =~ " ${label} " ]]; then
        LABELS_TO_REMOVE="${LABELS_TO_REMOVE}${label},"
      fi
    done

    if [[ -n "$LABELS_TO_REMOVE" ]]; then
      LABELS_TO_REMOVE=${LABELS_TO_REMOVE%,}
      gh pr edit "$pr_number" --remove-label "$LABELS_TO_REMOVE"
    fi

    # Add missing allowed labels
    for label in "${allowedLab[@]}"; do
      if [[ ! " ${currentLab[*]} " =~ " ${label} " ]]; then
        LABELS_TO_ADD="${LABELS_TO_ADD}${label},"
      fi
    done

    if [[ -n "$LABELS_TO_ADD" ]]; then
      LABELS_TO_ADD=${LABELS_TO_ADD%,}
      if ! gh pr edit "$pr_number" --add-label "$LABELS_TO_ADD" 2>/dev/null; then
        echo "Warning: Some labels may not exist in the repository: $LABELS_TO_ADD"
        # Try adding labels one by one to see which ones fail
        IFS=',' read -ra LABELS_TO_ADD <<<"$LABELS_TO_ADD"
        for single_label in "${LABELS_TO_ADD[@]}"; do
          if ! gh pr edit "$pr_number" --add-label "$single_label" 2>/dev/null; then
            echo "Failed to add label: $single_label (label may not exist)"
          else
            echo "Successfully added label: $single_label"
          fi
        done
      fi
    fi
  fi
}

main "$@"
