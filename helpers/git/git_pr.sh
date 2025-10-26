#!/usr/bin/env bash
### DOC
# prReady - describe what this script does
### DOC

# shellcheck disable=SC1091,SC2088,SC2164,SC2034,SC2154

set -euo pipefail

# Load required helper
loadHelpers global/colors
loadHelpers git/git

validatePkg git

# * Team 1
USERTEAM11=""
USERTEAM12=""
USERTEAM13=""
USERTEAM14=""
USERTEAM15=""
USERTEAM16=""
USERTEAM17=""
USERTEAM18=""

# * Team 2
USERTEAM21=""
USERTEAM22=""
USERTEAM23=""
USERTEAM24=""
USERTEAM25=""
USERTEAM26=""
USERTEAM27=""
USERTEAM28=""

# * Team 3
USERTEAM31=""
USERTEAM32=""
USERTEAM33=""
USERTEAM34=""
USERTEAM35=""
USERTEAM36=""
USERTEAM37=""
USERTEAM38=""

CUSTOM_TEAM_LIST=()
TEAM_LIST=''

# --- build list and string ---
teams=(TEAM1 TEAM2 TEAM3)

for team in "${teams[@]}"; do
  for i in {1..8}; do
    var="USER${team}${i}"
    val="${!var:-}"
    [[ -n "$val" ]] && CUSTOM_TEAM_LIST+=("$val")
  done
done

# Join with commas
TEAM_LIST=''
if ((${#CUSTOM_TEAM_LIST[@]})); then
  printf -v TEAM_LIST '%s,' "${CUSTOM_TEAM_LIST[@]}"
  TEAM_LIST="${TEAM_LIST%,}" # remove the last comma
fi

PROJECT_REPO=${PROJECT_REPO:-''}
LABELS_DRAFT_ADD=${LABELS_DRAFT_ADD:-''}
LABELS_READY_ADD=${LABELS_READY_ADD:-''}
LABELS_READY_REMOVE=${LABELS_READY_REMOVE:-''}

prNewDraft() {
  BASE="${1:-master}"

  gh pr create \
    --draft \
    --repo "$PROJECT_REPO" \
    --base "$BASE" \
    --label "$LABELS_DRAFT_ADD"
}

prDraftToOpen() { #    Git -> Draft to Open + Add Labels + Add Reviewers
  PR_NUMBER="$1"

  gh pr ready "$PR_NUMBER" \
    --repo "$PROJECT_REPO"
}

prReadyAddLabelsAndReviewers() { #    Git -> Yarn Format + Commit (autosquash) + Force push
  PR_NUMBER="$1"

  gh pr edit "$PR_NUMBER" \
    --repo "$PROJECT_REPO" \
    --add-label "$LABELS_READY_ADD" \
    --remove-label "$LABELS_READY_REMOVE" \
    --add-reviewer "$TEAM_LIST"
}
