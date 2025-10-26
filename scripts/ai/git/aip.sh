#!/usr/bin/env bash
### DOC
# Generate AI-crafted PR title and description from git changes
### DOC
#
# Uses Claude AI to analyze git diff between current branch and master/main,
# then generates a comprehensive PR title and body. Presents an interactive
# loop to accept, regenerate, or abort. Optionally saves to history.
#
# Usage:
#   dr aip [--no-save] [context...]
#
# Options:
#   --no-save            Skip saving to PR history
#   context              Additional context for PR generation
#
# Examples:
#   dr aip               # Generate PR description from branch changes
#   dr aip "refactor vault creation flow"  # Add context
#   dr aip --no-save     # Generate without saving to history
#
# Requirements:
#   - claude CLI tool
#   - Git repository with branch changes
#   - PR prompt template at ~/.config/ai-context/prompts/git-prompts
#   - glow (optional, for formatted display)
#
### DOC
set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helper
loadHelpers global/colors
loadHelpers git/

# Constants ────────────────────────────────────────────────────────────────
PROMPT_LOCATION="$HOME/.config/ai-context/prompts/git-prompts"
LLM_BODY_PROMPT="$PROMPT_LOCATION/pr-prompt.txt"
USER_CONTEXT_FILE="$PROMPT_LOCATION/prContext.txt"
HISTORY_DIR="$PROMPT_LOCATION/pr-history"

BASE_REMOTE=origin
BASE_BRANCH=${2:-master} # Default to 'main' if not provided

# ──────────────────────────────────────────────────────────────────────────
generate() {
  local argContext="$1"
  local currentBranch=$(git_current_branch)
  local context="Working task: [ $currentBranch ]"
  context+="\n"
  context+="$argContext"

  # Find merge-base with upstream
  git fetch "$BASE_REMOTE" "$BASE_BRANCH"
  local diff_base
  diff_base=$(git merge-base HEAD "$BASE_REMOTE/$BASE_BRANCH") || {
    echo -e "${YELLOW}⚠️  No common ancestor with $BASE_REMOTE/$BASE_BRANCH${RESET}"
    exit 1
  }

  # Build prompts
  local body_template prompt_body
  body_template=$(<"$LLM_BODY_PROMPT")
  prompt_body="${body_template//USER_CHANGES_CONTEXT/$context}"

  # Call LLM
  pr_body=$(git diff "$diff_base"...HEAD | claude -p --output-format "text" "$prompt_body")
}

print_result() {
  echo ""
  echo -e "${RED}-----------------${RESET}"
  echo ""
  echo "$pr_body" | glow - -w 120 || echo "$pr_body"
  echo
}

save_history() {
  mkdir -p "$HISTORY_DIR"
  ts=$(date +%s)
  cat >"$HISTORY_DIR/$ts.txt" <<EOF
# -------------------
$pr_body
EOF
  # Retain only the 6 newest files
  ls -1tr "$HISTORY_DIR" | head -n -6 | xargs -r -I{} rm "$HISTORY_DIR/{}"
}

main() {
  # ─── options ────────────────────────────────────────────────────────────
  local save_history=1
  if [[ "${1:-}" == "--no-save" ]]; then
    save_history=0
    shift
  fi

  local context="$*"
  [[ -z "$context" && -f "$USER_CONTEXT_FILE" ]] && context=$(<"$USER_CONTEXT_FILE")

  # ─── interactive loop ───────────────────────────────────────────────────
  while :; do
    generate "$context"
    clear
    print_result

    echo -ne "${GREEN}Accept [a] / ${YELLOW}Regenerate [r] / ${CYAN}Quit [q]? ${RESET}"
    read -r -s -n 1 choice
    case "${choice,,}" in
      a | "") # Accept (default)
        if ((save_history)); then save_history; fi
        echo -e "${GREEN}✅  Saved. Copy & paste into your GitHub PR.${RESET}"
        echo ""
        echo -e "${RED}-----------------${RESET}"
        echo ""
        echo "$pr_body"
        echo ""
        echo -e "${RED}-----------------${RESET}"
        echo ""
        break
        ;;
      r) # Regenerate
        echo -e "${YELLOW}🔄  Regenerating...${RESET}"
        ;;
      q) # Quit without saving
        echo -e "${YELLOW}🚫  Aborted (nothing saved).${RESET}"
        break
        ;;
      *) # Unknown
        echo "Please respond with a / r / q."
        ;;
    esac
  done
}

main "$@"
