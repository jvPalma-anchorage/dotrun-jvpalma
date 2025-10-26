#!/usr/bin/env bash
### DOC
# Generate AI-crafted commit message from git (stashed) changes
### DOC
#
# Uses Claude AI to analyze staged git changes (or branch diff) and generate
# a meaningful commit message. Presents an interactive loop to accept,
# regenerate, or abort the suggested message.
#
# Usage:
#   dr aic [--add] [--push] [--from BRANCHNAME] [context]
#
# Options:
#   --add                 Stage all changes before analyzing
#   --push                Automatically push after committing
#   --from BRANCHNAME     Compare with origin/BRANCHNAME instead of staged changes
#   context               Additional context for commit message generation
#
# Examples:
#   dr aic                # Generate from staged changes
#   dr aic --add          # Stage all changes first
#   dr aic --from master "refactor auth"  # Compare with master, add context
#
# Requirements:
#   - claude CLI tool
#   - Git repository with changes
#   - Commit prompt template at ~/.config/ai-context/prompts/git-prompts
#
### DOC
set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helper
loadHelpers global/colors
loadHelpers git/

# ─── constants ────────────────────────────────────────────────────────────
PROMPT_LOCATION="$HOME/.config/ai-context/prompts/git-prompts"
LLM_BODY_PROMPT="$PROMPT_LOCATION/commit-prompt.txt"
USER_CONTEXT_FILE="$PROMPT_LOCATION/prContext.txt"
HISTORY_DIR="$PROMPT_LOCATION/commit-history"

# ─── flags and context ────────────────────────────────────────────────────
add_all=0
auto_push=0
from_branch=""
context=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --add) add_all=1 ;;
    --push) auto_push=1 ;;
    --from)
      if [[ -n "${2:-}" && ! "$2" =~ ^-- ]]; then
        from_branch="$2"
        shift
      else
        echo -e "${RED}--from requires a branch name${RESET}"
        exit 1
      fi
      ;;
    -*)
      echo -e "${RED}Unknown option: $1${RESET}"
      exit 1
      ;;
    *)
      # Any non-flag argument is treated as context string
      if [[ -z "$context" ]]; then
        context="$1"
      else
        echo -e "${RED}Multiple context strings provided. Only one is allowed.${RESET}"
        exit 1
      fi
      ;;
  esac
  shift
done

# ─── check for changes ────────────────────────────────────────────────────
if [[ -n "$from_branch" ]]; then
  # Validate the branch exists
  git rev-parse --verify -q "origin/$from_branch" >/dev/null || {
    echo -e "${RED}Branch 'origin/$from_branch' does not exist.${RESET}"
    exit 1
  }

  # Find merge base for comparison
  MERGE_BASE=$(git merge-base HEAD "origin/$from_branch") || {
    echo -e "${RED}No common ancestor with 'origin/$from_branch'.${RESET}"
    exit 1
  }

  # Check if there are changes between current branch and the specified branch
  if git diff --quiet "$MERGE_BASE"...HEAD; then
    echo -e "${YELLOW}No changes between current branch and origin/$from_branch. Aborting.${RESET}"
    exit 0
  fi
else
  # Original behavior - check staged changes
  if git diff --cached --quiet; then
    echo -e "${YELLOW}No staged changes. Aborting.${RESET}"
    exit 0
  fi
fi

generate() {
  local argContext="$1"
  local currentBranch=$(git_current_branch)
  local context="Working task: [ $currentBranch ]"
  context+="\n"
  context+="$argContext"

  local body_template=$(<"$LLM_BODY_PROMPT")
  local prompt_body="${body_template//USER_CHANGES_CONTEXT/$context}"

  if [[ -n "$from_branch" ]]; then
    # Generate diff from merge base to current HEAD
    git diff "$MERGE_BASE"...HEAD | claude -p --output-format "text" "$prompt_body"
  else
    # Original behavior - use staged changes
    git diff --cached | claude -p --output-format "text" "$prompt_body"
  fi
}

main() {

  local context="$*"
  [[ -z "$context" && -f "$USER_CONTEXT_FILE" ]] && context=$(<"$USER_CONTEXT_FILE")

  # ─── interactive loop ────────────────────────────────────────────────────
  while :; do
    clear
    commit_msg=$(generate "$context" | head -2)
    echo -e "${GREEN}\n──────── Commit message ────────${RESET}\n$commit_msg\n"
    echo -ne "${GREEN}Accept [a] / ${YELLOW}Regenerate [r] / ${CYAN}Quit [q]? ${RESET}"
    read -r -s -n 1 choice
    echo # Print newline after choice
    case "${choice,,}" in
      a | "")

        # save history (10 latest)
        mkdir -p "$HISTORY_DIR"
        printf '%s\n' "$commit_msg" >"$HISTORY_DIR/$(date +%s).txt"
        ls -1tr "$HISTORY_DIR" | head -n -10 | xargs -r -I{} rm "$HISTORY_DIR/{}"
        echo -e "${GREEN}✅  Commit created.${RESET}"
        echo -e "${GREEN}\t git cmp \"${commit_msg}\"${RESET}"
        echo -e "${GREEN}\t jvp git commit -m \"${commit_msg}\"${RESET}"
        echo -e "${GREEN}\t dr aip \"${commit_msg}\"${RESET}"
        echo ""
        break
        ;;
      r) echo -e "${YELLOW}🔄  Regenerating...${RESET}" ;;
      q)
        echo -e "${YELLOW}🚫  Aborted.${RESET}"
        break
        ;;
      *) echo "Please respond with a / r / q." ;;
    esac
  done

}
main "$@"
