#!/usr/bin/env bash
### DOC
# Generate PR statistics CSV for authored merged PRs
### DOC
#
# Audits merged pull requests authored by you, collecting timing metrics,
# reviewer information, and label events. Outputs CSV with columns for
# creation time, label addition time, reviewers, and merge time with deltas.
#
# Usage:
#   dr prStats <owner/repo> <label-name>
#
# Arguments:
#   owner/repo           GitHub repository (e.g., myorg/myrepo)
#   label-name           Label to track timing for (e.g., "qa-approved")
#
# Examples:
#   dr prStats myorg/myrepo "qa-approved"  # Generate PR audit CSV
#
### DOC

set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helper
loadHelpers global/colors

REPO="${1:-}"
LABEL="${2:-}"

if [[ -z "$REPO" || -z "$LABEL" ]]; then
  echo "Usage: $0 <owner/repo> <label-name>" >&2
  exit 1
fi

echo "number,created_at,label_added_at,requested_reviewers,reviewers,merged_at,secs_created→label,secs_label→merged"

# Fetch up to 500 merged PRs you authored
mapfile -t PRS < <(gh pr list --repo "$REPO" \
  --author @me --state merged --limit 500 \
  --json number \
  --template '{{range .}}{{.number}}{{"\n"}}{{end}}')

for PR in "${PRS[@]}"; do
  # Basic PR metadata
  PR_JSON=$(gh api "repos/$REPO/pulls/$PR")
  CREATED=$(jq -r '.created_at' <<<"$PR_JSON")
  MERGED=$(jq -r '.merged_at' <<<"$PR_JSON")

  if ! PR_JSON=$(fetch_json "repos/$REPO/pulls/$PR"); then
    echo "WARN: unable to fetch PR #$PR after $GH_MAX_RETRIES attempts" >&2
    continue
  fi

  LABEL_EVENTS=$(fetch_json --paginate "repos/$REPO/issues/$PR/events") || LABEL_EVENTS=""
  LABEL_TIME=$(echo "$LABEL_EVENTS" | jq -r --arg L "$LABEL" '
  map(select(.event=="labeled" and .label.name==$L))
  | sort_by(.created_at)
  | .[0].created_at // empty')

  REQ_REVS_JSON=$(fetch_json "repos/$REPO/pulls/$PR/requested_reviewers") || REQ_REVS_JSON="{}"
  REQ_REVS=$(echo "$REQ_REVS_JSON" | jq -r '.users[].login' | paste -sd, -)

  REVIEWS_JSON=$(fetch_json --paginate "repos/$REPO/pulls/$PR/reviews") || REVIEWS_JSON="[]"
  REVIEWERS=$(echo "$REVIEWS_JSON" | jq -r '.[].user.login' | sort -u | paste -sd, -)

  # Time deltas (seconds)
  if [[ -n "$LABEL_TIME" ]]; then
    DELTA_1=$(($(date -d "$LABEL_TIME" +%s) - $(date -d "$CREATED" +%s)))
    DELTA_2=$(($(date -d "$MERGED" +%s) - $(date -d "$LABEL_TIME" +%s)))
  else
    DELTA_1=
    DELTA_2=
  fi

  echo "$PR,$CREATED,$LABEL_TIME,$REQ_REVS,$REVIEWERS,$MERGED,$DELTA_1,$DELTA_2"
done
