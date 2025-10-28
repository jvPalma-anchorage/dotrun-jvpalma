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
loadHelpers global/logging
loadHelpers git

# Constants ────────────────────────────────────────────────────────────────
SCRIPT_LOCATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_LOCATION="$SCRIPT_LOCATION_DIR/.prompts/git"
# LLM_BODY_PROMPT="$PROMPT_LOCATION/commit-prompt.md"
LLM_BODY_PROMPT="$PROMPT_LOCATION/pull-request-prompt.md"

USER_CONTEXT_FILE="$PROMPT_LOCATION/user-to-ai-context.md"

FINAL_PROMPT="$PROMPT_LOCATION/REVIEW_PROMPT.md"
ACCEPTED_OUTPUT_FOR_REVIEW="$PROMPT_LOCATION/ACCEPTED_OUTPUT_FOR_REVIEW.md"

# HISTORY_DIR="$PROMPT_LOCATION/commit-history"
HISTORY_DIR="$PROMPT_LOCATION/pr-history"

BASE_REMOTE=origin
BASE_BRANCH=${2:-master} # Default to 'main' if not provided

# ─── cleanup temp files on exit ───────────────────────────────────────────
cleanup_temp_files() {
  [[ -f "$FINAL_PROMPT" ]] && rm -f "$FINAL_PROMPT"
  [[ -f "$ACCEPTED_OUTPUT_FOR_REVIEW" ]] && rm -f "$ACCEPTED_OUTPUT_FOR_REVIEW"
}
trap cleanup_temp_files EXIT

# ─── helper: read commit history ──────────────────────────────────────────
read_commit_history() {
  local history=""

  if [[ -d "$HISTORY_DIR" ]] && [[ -n "$(ls -A "$HISTORY_DIR" 2>/dev/null)" ]]; then
    # Read files in chronological order (oldest first)
    while IFS= read -r file; do
      local content
      content=$(<"$HISTORY_DIR/$file")
      history+="- ${content}\n"
    done < <(ls -1tr "$HISTORY_DIR" 2>/dev/null)
  fi

  echo -e "$history"
}

save_history() {
  mkdir -p "$HISTORY_DIR"
  ts=$(date +%s)
  cat >"$HISTORY_DIR/$ts.txt" <<EOF
# -------------------
$1
EOF
  # Retain only the 10 newest files
  ls -1tr "$HISTORY_DIR" | head -n -10 | xargs -r -I{} rm "$HISTORY_DIR/{}"

  log_info " ✅  Saved for future examples"
}

# ─── helper: open editor with y/n prompt ──────────────────────────────────
prompt_editor_review() {
  local file="$1"
  local prompt_msg="${2:-Is the content ready?}"

  # Open in editor
  ${EDITOR:-nano} "$file"

  # Prompt for confirmation
  echo -ne "${prompt_msg} [${GREEN}Y${RESET}/${RED}n${RESET}] (${GREEN}Enter=Yes${RESET}, ${RED}ESC=No${RESET}): "

  # Read single character with escape sequence support
  local choice
  IFS= read -r -s -n 1 choice
  echo # newline

  # Check for escape sequence (ESC key sends ^[ which is \x1b)
  if [[ "$choice" == $'\x1b' ]]; then
    return 1
  fi

  # Accept empty (Enter), 'y', or 'Y' as yes
  if [[ -z "$choice" ]] || [[ "${choice,,}" == "y" ]]; then
    return 0
  fi

  # Anything else is no
  return 1
}

get_code_diffs() {

  # Find merge-base with upstream
  git fetch "$BASE_REMOTE" "$BASE_BRANCH"
  local diff_base
  diff_base=$(git merge-base HEAD "$BASE_REMOTE/$BASE_BRANCH") || {
    log_warning "${YELLOW}⚠️  No common ancestor with $BASE_REMOTE/$BASE_BRANCH${RESET}"
    exit 1
  }

  git diff "$diff_base"...HEAD

}

prepare_prompt() {
  local context=""
  local prompt_body=""

  #* 1) Get Branch name for additional Context
  local currentBranch=$(git_current_branch)
  context+="Working task: [ $currentBranch ]"

  #* 2) Get user inline message
  local argContext="$1"
  context+="$argContext"

  #* 3) Get Prompt Template
  local body_template=$(<"$LLM_BODY_PROMPT")
  prompt_body="$body_template"

  #* 4) Get commit history to provide AI reviewed Examples
  local user_history=$(read_commit_history)

  #* 5) Get code Diffs for inline context
  local code_diffs=$(get_code_diffs)

  #* 6) ADD `User Context` to the prompt
  prompt_body="${prompt_body//USER_CHANGES_CONTEXT/$context}"

  #* 7) ADD `Generated Commits History` to the prompt
  prompt_body="${prompt_body//USER_HISTORY_CONTEXT/$user_history}"

  #* 8) ADD `code Diffs` to the prompt
  prompt_body="${prompt_body//CODE_DIFFS/$code_diffs}"

  # Save to temp file for review
  echo "$prompt_body" >"$FINAL_PROMPT"
}

# ──────────────────────────────────────────────────────────────────────────

generate() {
  # Read reviewed prompt
  local reviewed_prompt=$(<"$FINAL_PROMPT")

  # Call Claude with reviewed prompt
  claude -p --output-format "text" "$reviewed_prompt"
}

print_result() {
  local pr_output="$1"

  echo ""
  echo -e "${RED}-----------------${RESET}"
  echo ""
  echo "$pr_output" | glow - -w 110 || echo "$pr_output"
  echo
}

main() {
  # ─── options ────────────────────────────────────────────────────────────
  local should_save_history=1
  if [[ "${1:-}" == "--no-save" ]]; then
    should_save_history=0
    shift
  fi

  local context="$*"
  [[ -z "$context" && -f "$USER_CONTEXT_FILE" ]] && context=$(<"$USER_CONTEXT_FILE")

  # ─── interactive loop ───────────────────────────────────────────────────
  while :; do
    clear

    # Prepare prompt (builds the AI prompt with context and history)
    prepare_prompt "$context"

    # Open editor for prompt review
    if ! prompt_editor_review "$FINAL_PROMPT" "Is the prompt ready?"; then
      log_warning "${YELLOW}⚠️  Prompt review cancelled.${RESET}"
      break
    fi
    log_success "Accepted. generating..."

    # Generate PR description
    local pr_output
    pr_output=$(generate)

    print_result "$pr_output"

    echo -ne "${GREEN}Accept & Review [a] / ${YELLOW}Regenerate [r] / ${CYAN}Quit [q]? ${RESET}"
    read -r -s -n 1 choice
    echo # newline
    case "${choice,,}" in
      a | "") # Accept (default)

        local reviewed_output=''

        # Save to review file and open for editing
        echo "$pr_output" >"$ACCEPTED_OUTPUT_FOR_REVIEW"

        if ! prompt_editor_review "$ACCEPTED_OUTPUT_FOR_REVIEW" "Is the PR description ready?"; then
          log_warning "${YELLOW}⚠️  PR description rejected. Discarding...${RESET}"
          rm -f "$FINAL_PROMPT" "$ACCEPTED_OUTPUT_FOR_REVIEW"
          log_info "${YELLOW}🔄  Regenerating...${RESET}"
          continue
        fi

        # Read the reviewed PR description
        reviewed_output=$(<"$ACCEPTED_OUTPUT_FOR_REVIEW")

        if ((should_save_history)); then save_history "$reviewed_output"; fi
        echo ""
        echo -e "${RED}-----------------${RESET}"
        echo ""
        echo "$reviewed_output"
        echo ""
        echo -e "${RED}-----------------${RESET}"
        echo ""
        break
        ;;
      r) log_info "${YELLOW}🔄  Regenerating...${RESET}" ;;
      q)
        log_info "${YELLOW}🚫  Aborted.${RESET}"
        break
        ;;
      *) echo "Please respond with a / r / q." ;;
    esac
  done
}

main "$@"
