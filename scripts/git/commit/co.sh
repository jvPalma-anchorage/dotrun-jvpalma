#!/usr/bin/env bash
### DOC
# Smart git [C]heck[O]ut with branch name normalization
### DOC
#
# Intelligent branch checkout that handles local branches, remote branches,
# and new branch creation. Automatically normalizes branch names (e.g.,
# converts 'originName/' to 'newName/' and uppercases ticket prefixes).
#
# Usage:
#   dr co <branch-name>
#
# Behavior:
#   1) Checks if branch exists locally → git checkout <name>
#   2) Else checks if exists on origin → fetch and create tracking branch
#   3) Else creates new branch with sanitized name
#
# Examples:
#   dr co feature-branch              # Checkout existing or create new
#   dr co originName/atlas-123-fix     # Normalizes to newName/ATLAS-123-fix
#   dr co origin-branch               # Fetches from origin if not local
#
### DOC
set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helper
loadHelpers global/colors
loadHelpers git/git_pr

validatePkg git

NAME_TO_REPLACE=""
NEW_NAME=""
BRANCH_NAME_FORMAT='CAMEL_CASE' # Options: CAMEl_CASE, SNAKE_CASE, KEBAB_CASE

# --- helpers -----------------------------------------------------------------
usage() {
  echo "Usage: co <branch-name>" >&2
  exit 2
}

# --- sanitize ---------------------------------------------------------------

sanitize_branch_name() {
  local input="${1:-}"

  # If it doesn't start with $NAME_TO_REPLACE or $NEW_NAME/, leave as is.
  if [[ "$input" != $NAME_TO_REPLACE/* && "$input" != $NEW_NAME/* ]]; then
    printf '%s\n' "$input"
    return 0
  fi

  # Normalize prefix to NEW_NAME
  local rest="${input#*/}"
  local prefix="$NEW_NAME"

  # First, handle the hyphen-based capitalization (if applicable)
  if [[ "$rest" == *-* ]]; then
    local first="${rest%%-*}"    # before first hyphen
    local remainder="${rest#*-}" # after first hyphen
    first="${first^^}"           # uppercase (ASCII)
    rest="${first}-${remainder}"
  fi

  # Then format according to BRANCH_NAME_FORMAT
  if [[ "$BRANCH_NAME_FORMAT" == "SNAKE_CASE" ]]; then
    rest="${rest//-/_}"
  elif [[ "$BRANCH_NAME_FORMAT" == "CAMEL_CASE" ]]; then
    IFS='-' read -ra parts <<<"$rest"
    local camel_cased=""
    for part in "${parts[@]}"; do
      camel_cased+="${part^}"
    done
    rest="$camel_cased"
  elif [[ "$BRANCH_NAME_FORMAT" == "KEBAB_CASE" ]]; then
    rest="${rest,,}"
  fi

  printf '%s/%s\n' "$prefix" "$rest"
}

# --- main -------------------------------------------------------------------

main() {
  [[ $# -eq 1 ]] || usage
  ensure_git_repo

  local input="$1"
  local sanitized

  # if NAME_TO_REPLACE OR NEW_NAME is unset/no value, skip sanitization
  if [[ -z "$NAME_TO_REPLACE" && -z "$NEW_NAME" ]]; then
    sanitized="$input"
  else
    sanitized="$(sanitize_branch_name "$input")"
  fi

  # Try exact input first, then the sanitized variant (if different)
  # This lets "$NAME_TO_REPLACE/atlas-..." find "$NEW_NAME/ATLAS-..." that already exists.
  local candidates=("$input")
  if [[ "$sanitized" != "$input" ]]; then
    candidates+=("$sanitized")
  fi

  # 1) Local?
  for name in "${candidates[@]}"; do
    if is_local_branch "$name"; then
      checkout_local "$name"
      return 0
    fi
  done

  # 2) Remote on origin?
  if has_origin; then
    for name in "${candidates[@]}"; do
      if is_remote_branch "$name"; then
        checkout_remote "$name"
        return 0
      fi
    done
  fi

  # 3) Create new with sanitized name
  create_new_branch "$sanitized"
}

main "$@"
