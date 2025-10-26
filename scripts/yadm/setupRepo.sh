#!/usr/bin/env bash
### DOC
# Initialize yadm with private GitHub repository
### DOC
#
# Interactive setup script that creates a private GitHub repository, configures
# yadm to use it, and pushes an initial commit. Handles authentication, SSH vs
# HTTPS selection, and provides guidance for next steps. Sets master as default
# branch.
#
# Usage:
#   dr setupRepo         # Interactive setup with prompts
#
# Requirements:
#   - git
#   - yadm
#   - gh (GitHub CLI)
#   - GitHub authentication
#
### DOC
set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helper
loadHelpers global/colors

# --- helpers ---
prompt() {
  local p="$1" d="${2:-}"
  read -r -p "$p" REPLY || true
  echo "${REPLY:-$d}"
}

need_cmd() { command -v "$1" >/dev/null 2>&1 || return 1; }

main() {
  echo "${BOLD}${PURPLE}=== Configure yadm with private GitHub repository ===${RESET}"
  echo ""

  # 1) Initial questions
  REPO_NAME="$(prompt "${CYAN}Repository name [dotrun]: ${RESET}" 'dotrun')"
  VISIBILITY="--private" # requested: private
  BASE_BRANCH="master"   # requested: master

  # 2) Debian: install dependencies (git, yadm, gh)
  echo "${BLUE}==> Installing dependencies (git, yadm, gh)...${RESET}"
  sudo apt-get update -y
  need_cmd git || sudo apt-get install -y git
  need_cmd yadm || sudo apt-get install -y yadm
  if ! need_cmd gh; then
    # GitHub CLI might be in the official Ubuntu/Debian repo
    sudo apt-get install -y gh || {
      echo "${RED}✗ Failed to install 'gh' from repositories. Check GitHub CLI docs.${RESET}"
      exit 1
    }
  fi

  # 3) GitHub auth (if necessary)
  if ! gh auth status >/dev/null 2>&1; then
    echo "${YELLOW}==> You are not authenticated to GitHub CLI. Opening login flow...${RESET}"
    gh auth login -s repo -w
  fi

  # 4) Ensure default branch = master
  echo "${BLUE}==> Setting '${BOLD}master${RESET}${BLUE}' as default Git branch.${RESET}"
  git config --global init.defaultBranch "$BASE_BRANCH"

  # 5) Create empty private repository on GitHub
  echo "${BLUE}==> Creating repository on GitHub: ${BOLD}${REPO_NAME}${RESET}${BLUE} (private, empty)${RESET}"
  # Default owner = authenticated user
  OWNER="$(gh api user -q .login)"
  # Create empty (without README) to avoid polluting $HOME when pulling
  gh repo create "${OWNER}/${REPO_NAME}" ${VISIBILITY} --confirm

  # 6) Configure yadm in $HOME (initialize if necessary)
  if yadm rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "${GREEN}==> yadm is already initialized. Reusing existing repository.${RESET}"
  else
    echo "${BLUE}==> Initializing yadm in your \$HOME…${RESET}"
    yadm init
  fi

  # 7) Point yadm remote to new repo (SSH by default; fall back to HTTPS if no SSH)
  REMOTE_SSH="git@github.com:${OWNER}/${REPO_NAME}.git"
  REMOTE_HTTPS="https://github.com/${OWNER}/${REPO_NAME}.git"

  USE_HTTPS=0
  if [ ! -f "${HOME}/.ssh/id_rsa" ] && [ ! -f "${HOME}/.ssh/id_ed25519" ]; then
    # No SSH key detected; use HTTPS
    USE_HTTPS=1
    echo "${YELLOW}⚠ No SSH key detected, using HTTPS${RESET}"
  fi

  if yadm remote get-url origin >/dev/null 2>&1; then
    echo "${BLUE}==> Remote 'origin' already exists in yadm. Updating URL…${RESET}"
    if [ "$USE_HTTPS" -eq 1 ]; then
      yadm remote set-url origin "$REMOTE_HTTPS"
    else
      yadm remote set-url origin "$REMOTE_SSH"
    fi
  else
    echo "${BLUE}==> Adding remote 'origin' to yadm…${RESET}"
    if [ "$USE_HTTPS" -eq 1 ]; then
      yadm remote add origin "$REMOTE_HTTPS"
    else
      yadm remote add origin "$REMOTE_SSH"
    fi
  fi

  # 8) Make first empty commit and push (to create master branch on remote)
  echo "${BLUE}==> Creating initial commit and pushing to '${BOLD}${BASE_BRANCH}${RESET}${BLUE}'…${RESET}"
  yadm commit --allow-empty -m "Initialize yadm repo"
  yadm branch -M "$BASE_BRANCH"
  yadm push -u origin "$BASE_BRANCH"

  echo ""
  echo "${BOLD}${GREEN}✔ Done.${RESET}"
  echo ""
  echo "${BOLD}GitHub Repository:${RESET}  ${CYAN}https://github.com/${OWNER}/${REPO_NAME}${RESET}"
  echo "${BOLD}Remote (yadm):${RESET}      ${CYAN}$(yadm remote get-url origin)${RESET}"
  echo "${BOLD}Base branch:${RESET}        ${CYAN}${BASE_BRANCH}${RESET}"
  echo ""
  echo "${BOLD}${PURPLE}Next steps (examples):${RESET}"
  echo "  ${GRAY}# Start versioning dotfiles in your \$HOME${RESET}"
  echo "  ${YELLOW}yadm add ~/.zshrc ~/.gitconfig${RESET}"
  echo "  ${YELLOW}yadm commit -m \"Add initial dotfiles\"${RESET}"
  echo "  ${YELLOW}yadm push${RESET}"
  echo ""
  echo "${BOLD}${PURPLE}Tip:${RESET}"
  echo "  ${GRAY}- If you want to use SSH but don't have keys:${RESET}"
  echo "    ${YELLOW}ssh-keygen -t ed25519 -C \"${OWNER}@\$(hostname)\"${RESET}"
  echo "    ${YELLOW}gh ssh-key add ~/.ssh/id_ed25519.pub -t \"yadm on \$(hostname)\"${RESET}"
  echo ""
}

main "$@"
