#!/usr/bin/env bash
### DOC
# Generate diff patch file for code review
### DOC
#
# Creates a timestamped patch file containing the diff between the current
# branch and the base branch (main or master), excluding build artifacts.
#
# Output: code-review-YYYYMMDD-HHMMSS.patch
#
# Excludes: node_modules, dist, build, .next, coverage, lock files
#
# Usage:
#   dr codeRev
#
### DOC
set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helper
# loadHelpers global/colors
# loadHelpers global/logging
# loadHelpers git

main() {
  BASEBRANCH="$(git branch -r --list origin/main origin/master | head -n1 | awk -F/ '{print $2}')" \
    && BASECOMMIT="$(git merge-base HEAD "origin/$BASEBRANCH")" \
    && OUTFILE="$PWD/code-review-$(date +%Y%m%d-%H%M%S).patch" \
    && git diff --no-color "$BASECOMMIT"..HEAD -- \
      . ':(exclude)node_modules' ':(exclude)dist' ':(exclude)build' ':(exclude).next' \
      ':(exclude)coverage' ':(exclude)*lock*' >"$OUTFILE" \
    && echo "Wrote diff to $OUTFILE"
}

main "$@"
