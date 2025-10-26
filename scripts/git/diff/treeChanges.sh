#!/usr/bin/env bash
### DOC
# Display git changes as colored tree structure
### DOC
#
# Displays changed files as a tree structure with color-coded status:
# - 🟢 Green: Added files
# - 🟡 Yellow: Modified files
# - 🔴 Red: Deleted files
# - 🔵 Cyan: Renamed/Copied files
#
# Usage:
#   dr treeChanges                 # Compare with origin/master
#   dr treeChanges origin/develop  # Compare with develop branch
#
### DOC

set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helper
# loadHelpers global/colors
loadHelpers global/logging
loadHelpers git

# -------- choose branch to compare against --------------------------
BASE="${1:-origin/master}"

ensure_git_repo

exitIfNoBranchName

MERGE_BASE=$(git merge-base HEAD "$BASE") || {
  log_error "No common ancestor with '$BASE'."
  exit 1
}

# ---------- 2. icons & colors --------------
ICON_A="" CLR_A=$GREEN  # Added
ICON_M="" CLR_M=$YELLOW # Modified
ICON_D="" CLR_D=$RED    # Deleted
ICON_R="" CLR_R=$CYAN   # Rename/Copy

# ---------- 3. print tree -------------
declare -A SEEN_DIRS

git diff --name-status -z "$MERGE_BASE"...HEAD \
  | while true; do
    # 1) status (A/M/D/R100/C90…) — ends with NUL
    read -r -d '' status || break
    # 2) first path — ends with NUL
    read -r -d '' path1 || break

    status_letter=${status:0:1} # keep only A/M/D/R/C
    path=$path1

    # If rename/copy, there's a 3rd field: the new name
    if [[ $status_letter == R || $status_letter == C ]]; then
      read -r -d '' path2 || break
      path=$path2
      status_letter=M # treat as "modified"
    fi

    # Extra protection (shouldn't happen)
    [[ -z $path ]] && continue

    # Split path into parts
    IFS='/' read -ra PARTS <<<"$path"

    # Print directories (only once each)
    dir=""
    for ((i = 0; i < ${#PARTS[@]} - 1; i++)); do
      dir+="${PARTS[i]}/"
      [[ ${SEEN_DIRS[$dir]+x} ]] && continue
      printf '%*s%s/\n' $((i * 2)) '' "${PARTS[i]}"
      SEEN_DIRS[$dir]=1
    done

    # Choose color + icon
    case "$status_letter" in
      A)
        color=$CLR_A
        icon=$ICON_A
        ;;
      M)
        color=$CLR_M
        icon=$ICON_M
        ;;
      D)
        color=$CLR_D
        icon=$ICON_D
        ;;
      *)
        color=$CLR_R
        icon=$ICON_R
        ;; # renames/copies
    esac

    printf '%*s%s%s %s%s\n' $(((${#PARTS[@]} - 1) * 2)) '' \
      "$color" "$icon" "${PARTS[-1]}" "$RESET"
  done
