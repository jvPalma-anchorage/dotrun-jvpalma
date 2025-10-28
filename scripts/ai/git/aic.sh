#!/usr/bin/env bash
### DOC
# Generate AI-crafted commit message from git (stashed) changes
### DOC
#
# Uses Claude AI to analyze staged git changes (or branch diff) and generate
# a meaningful commit message. The process includes:
# 1. Reads previous commit history for context
# 2. Opens the AI prompt in your editor for review before sending
# 3. Presents an interactive loop to accept, regenerate, or abort
# 4. Opens accepted commit message in editor for final review
#
# Usage:
#   dr aic [--from BRANCHNAME] [context]
#
# Options:
#   --from BRANCHNAME     Compare with origin/BRANCHNAME instead of staged changes
#   context               Additional context for commit message generation
#
# Examples:
#   dr aic                                # Generate from staged changes
#   dr aic "refactor auth"                # Add context
#   dr aic --from master "refactor auth"  # Compare with master, add context
#
### DOC
set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helper
loadHelpers global/colors
loadHelpers global/logging
loadHelpers git

# ─── constants ────────────────────────────────────────────────────────────
SCRIPT_LOCATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_LOCATION="$SCRIPT_LOCATION_DIR/.prompts/git"
LLM_BODY_PROMPT="$PROMPT_LOCATION/commit-prompt.md"
# LLM_BODY_PROMPT="$PROMPT_LOCATION/pull-request-prompt.md"

USER_CONTEXT_FILE="$PROMPT_LOCATION/user-to-ai-context.md"

FINAL_PROMPT="$PROMPT_LOCATION/REVIEW_PROMPT.md"
ACCEPTED_OUTPUT_FOR_REVIEW="$PROMPT_LOCATION/ACCEPTED_OUTPUT_FOR_REVIEW.md"

HISTORY_DIR="$PROMPT_LOCATION/commit-history"
# HISTORY_DIR="$PROMPT_LOCATION/pr-history"

# ─── flags and context ────────────────────────────────────────────────────
from_branch=""
context=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)
      if [[ -n "${2:-}" && ! "$2" =~ ^-- ]]; then
        from_branch="$2"
        shift
      else
        log_error "${RED}--from requires a branch name"
        exit 1
      fi
      ;;
    -*)
      log_error "${RED}Unknown option: $1"
      exit 1
      ;;
    *)
      # Any non-flag argument is treated as context string
      if [[ -z "$context" ]]; then
        context="$1"
      else
        log_error "${RED}Multiple context strings provided. Only one is allowed."
        exit 1
      fi
      ;;
  esac
  shift
done

clear

# ─── check for changes ────────────────────────────────────────────────────
if [[ -n "$from_branch" ]]; then
  # Validate the branch exists
  git rev-parse --verify -q "origin/$from_branch" >/dev/null || {
    log_error "${RED}Branch 'origin/$from_branch' does not exist."
    exit 1
  }

  # Find merge base for comparison
  MERGE_BASE=$(git merge-base HEAD "origin/$from_branch") || {
    log_error "${RED}No common ancestor with 'origin/$from_branch'."
    exit 1
  }

  # Check if there are changes between current branch and the specified branch
  if git diff --quiet "$MERGE_BASE"...HEAD; then
    log_warning "${YELLOW}No changes between current branch and origin/$from_branch. Aborting."
    exit 0
  fi
else
  # Original behavior - check staged changes
  if git diff --cached --quiet; then
    log_warning "${YELLOW}No staged changes. Aborting."
    exit 0
  fi
fi

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
  # Call Claude with reviewed prompt
  if [[ -n "$from_branch" ]]; then
    # Generate diff from merge base to current HEAD
    git diff "$MERGE_BASE"...HEAD
  else
    # Original behavior - use staged changes
    git diff --cached
  fi
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

generate() {
  # Read reviewed prompt
  local reviewed_prompt=$(<"$FINAL_PROMPT")

  # Call Claude with reviewed prompt
  claude -p --output-format "text" "$reviewed_prompt"
}

main() {

  local context="$*"
  [[ -z "$context" && -f "$USER_CONTEXT_FILE" ]] && context=$(<"$USER_CONTEXT_FILE")

  # ─── interactive loop ────────────────────────────────────────────────────
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

    # Generate commit message using the reviewed prompt
    local commit_msg
    commit_msg=$(generate | head -2)

    echo -e "${GREEN}\n──────── Commit message ────────${RESET}\n$commit_msg\n"
    echo -ne "${GREEN}Accept & Review [a] / ${YELLOW}Regenerate [r] / ${CYAN}Quit [q]? ${RESET}"
    read -r -s -n 1 choice
    echo # Print newline after choice
    case "${choice,,}" in
      a | "")

        local reviewed_output=''
        # Save to review file and open for editing
        echo "$commit_msg" >"$ACCEPTED_OUTPUT_FOR_REVIEW"

        if ! prompt_editor_review "$ACCEPTED_OUTPUT_FOR_REVIEW" "Is the commit message ready?"; then
          log_warning "${YELLOW}⚠️  Commit message rejected. Discarding...${RESET}"
          rm -f "$FINAL_PROMPT" "$ACCEPTED_OUTPUT_FOR_REVIEW"
          log_info "${YELLOW}🔄  Regenerating...${RESET}"
          continue
        fi

        # Read the reviewed commit message
        reviewed_output=$(<"$ACCEPTED_OUTPUT_FOR_REVIEW")

        # Save to history (10 latest)
        save_history "$reviewed_output"
        echo
        echo -e "${GREEN}\t ${GREEN}git ${RESET}commit -m ${YELLOW}\"${reviewed_output}\"${RESET}"
        echo -e "${GREEN}\t ${GREEN}dr ${RESET}aip ${YELLOW}\"${reviewed_output}\"${RESET}"
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
