#!/usr/bin/env bash
### DOC
# Stage, fixup commit, autosquash rebase, and force push
### DOC
#
# Automates the workflow of adding all changes, creating a fixup commit,
# rebasing with autosquash, and force pushing to remote.
#
# Usage:
#   dr autosquashCommit [N]
#
# Arguments:
#   N    Number of commits to rebase (default: 2)
#
# Examples:
#   dr autosquashCommit      # Fixup last 2 commits
#   dr autosquashCommit 3    # Fixup last 3 commits
#
# Operations:
# 1. git add -A                       Stage all changes
# 2. git commit --fixup=HEAD          Create fixup commit
# 3. git rebase -i HEAD~N --autosquash  Interactive rebase with autosquash
# 4. git push --force-with-lease      Safe force push
#
# Warning: Uses force push! Ensure you're on the correct branch.
#
### DOC

main() {
  local num
  num=2

  if [ "$#" -ge 1 ]; then
    num="$1"
  fi

  HUMAN_VERIFIED=true git add -A
  HUMAN_VERIFIED=true git commit --fixup=HEAD
  HUMAN_VERIFIED=true git rebase -i HEAD~${num:-2} --autosquash
  HUMAN_VERIFIED=true git push --force-with-lease

}

main "$@"
