#!/usr/bin/env bash
### DOC
# Manage Claude Code slash commands for Linear workflow
### DOC
#
# This script displays available linearSync commands and prompts
# the user to import them into their global Claude Code commands directory.
#
# Usage/Example:
#  dr linearCommands
#
# Required Tools:
#  - yq (optional, for robust YAML parsing - falls back to grep if unavailable)
#
### DOC

set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helpers
loadHelpers global/logging
loadHelpers global/colors

#==============================================================================
# CONFIGURATION
#==============================================================================

# Pattern to match command files (used with find)
readonly COMMAND_FILE_PATTERN="linearSync-*.md"

# Custom display order (hardcoded for linearSync workflow)
# This determines the sequence shown to the user
readonly DISPLAY_ORDER=(
  "linearSync-init"
  "---"
  "linearSync-teamProjects"
  "linearSync-userProjects"
  "---"
  "linearSync-setActiveProject"
  "linearSync-AP-details"
  "linearSync-AP-myIssues"
  "linearSync-AP-disciplineIssues"
  "linearSync-AP-otherIssues"
  "---"
  "linearSync-status"
  "linearSync-NextTask"
)

# Target directory for Claude Code commands
readonly CLAUDE_COMMANDS_DIR="$HOME/.claude/commands"

# Source directory (relative to script location)
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly COMMANDS_SOURCE_DIR="$SCRIPT_DIR/.commands"

#==============================================================================
# HELPER FUNCTIONS (Generic - Reusable)
#==============================================================================

# Extract description from YAML front matter
# Args: $1 = file path
# Returns: description string or "No description available"
extract_description() {
  local file="$1"
  local description=""

  # Try yq first (most robust)
  if command -v yq &>/dev/null; then
    description=$(yq eval '.description // ""' "$file" 2>/dev/null || echo "")
  fi

  # Fallback to awk/grep if yq unavailable or failed
  if [[ -z "$description" ]]; then
    description=$(awk '
      /^---$/ { if (++count == 2) exit }
      count == 1 && /^description:/ {
        sub(/^description: */, "")
        gsub(/^["'\'']+|["'\'']+$/, "")
        print
        exit
      }
    ' "$file" 2>/dev/null || echo "")
  fi

  # Return result or fallback message
  if [[ -n "$description" ]]; then
    echo "$description"
  else
    echo "No description available"
  fi
}

# Get slash command name from filename
# Args: $1 = file path
# Returns: slash command (e.g., "/linearSync-init")
get_slash_command() {
  local file="$1"
  local basename
  basename="$(basename "$file" .md)"
  echo "/$basename"
}

# Display a single command entry with colors
# Args: $1 = slash command, $2 = description
display_command() {
  local cmd="$1"
  local desc="$2"
  printf "${CYAN}%-35s${RESET} - ${YELLOW}%s${RESET}\n" "$cmd" "$desc"
}

# Check if a file exists in the source directory
# Args: $1 = basename (without .md extension)
# Returns: 0 if exists, 1 otherwise
command_file_exists() {
  local basename="$1"
  [[ -f "$COMMANDS_SOURCE_DIR/${basename}.md" ]]
}

# Display all commands in the specified order
display_commands() {
  local cmd_file cmd_name description
  local found_count=0
  local missing_files=()

  echo ""
  log_info "Available Linear Sync Commands:"
  echo ""

  for cmd_name in "${DISPLAY_ORDER[@]}"; do
    # Handle separator entries
    if [[ "$cmd_name" == "---" ]]; then
      echo "${GRAY}──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${RESET}"
      continue
    fi

    cmd_file="$COMMANDS_SOURCE_DIR/${cmd_name}.md"

    if [[ -f "$cmd_file" ]]; then
      description=$(extract_description "$cmd_file")
      display_command "/$cmd_name" "$description"
      found_count=$((found_count + 1))
    else
      missing_files+=("$cmd_name")
    fi
  done

  echo ""

  # Report any missing files (helpful for debugging)
  if [[ ${#missing_files[@]} -gt 0 ]]; then
    log_warning "Missing files (not found in source directory):"
    for missing in "${missing_files[@]}"; do
      echo "  - ${missing}.md"
    done
    echo ""
  fi

  log_info "Found ${found_count} command(s) ready for import"
  echo ""
}

# Prompt user for confirmation
# Returns: 0 for yes, 1 for no
prompt_user() {
  local response
  echo -n "${BOLD}${GREEN}Import these commands to ~/.claude/commands? [y/N]:${RESET} "
  read -r response
  [[ "$response" =~ ^[Yy]$ ]]
}

# Import commands to Claude Code directory
import_commands() {
  local cmd_file cmd_name
  local imported_count=0
  local skipped_count=0
  local failed_count=0

  # Ensure target directory exists
  if ! mkdir -p "$CLAUDE_COMMANDS_DIR" 2>/dev/null; then
    log_error "Failed to create directory: $CLAUDE_COMMANDS_DIR"
    return 1
  fi

  echo ""
  log_info "Importing commands..."
  echo ""

  for cmd_name in "${DISPLAY_ORDER[@]}"; do
    # Skip separator entries
    if [[ "$cmd_name" == "---" ]]; then
      continue
    fi

    cmd_file="$COMMANDS_SOURCE_DIR/${cmd_name}.md"

    if [[ ! -f "$cmd_file" ]]; then
      continue
    fi

    local target_file="$CLAUDE_COMMANDS_DIR/${cmd_name}.md"

    # Check if file already exists
    if [[ -f "$target_file" ]]; then
      echo "  ${YELLOW}⊙${RESET} /$cmd_name (already exists, skipping)"
      skipped_count=$((skipped_count + 1))
    else
      if cp "$cmd_file" "$target_file" 2>/dev/null; then
        echo "  ${GREEN}✓${RESET} /$cmd_name"
        imported_count=$((imported_count + 1))
      else
        echo "  ${RED}✗${RESET} /$cmd_name (failed to copy)"
        failed_count=$((failed_count + 1))
      fi
    fi
  done

  echo ""

  # Summary
  log_success "Import complete:"
  echo "  - Imported: ${imported_count}"
  [[ $skipped_count -gt 0 ]] && echo "  - Skipped: ${skipped_count}"
  [[ $failed_count -gt 0 ]] && echo "  - Failed: ${failed_count}"
  echo ""

  if [[ $imported_count -gt 0 ]]; then
    log_info "Commands are now available in Claude Code!"
    log_info "Try: ${CYAN}/linearSync-init${RESET}"
  fi
}

#==============================================================================
# MAIN FUNCTION
#==============================================================================

main() {
  # Validate source directory exists
  if [[ ! -d "$COMMANDS_SOURCE_DIR" ]]; then
    log_error "Commands source directory not found: $COMMANDS_SOURCE_DIR"
    return 1
  fi

  # Display header
  echo ""
  echo "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════════════════════════════════${RESET}"
  echo "${BOLD}${BLUE}══════════════════════════  Linear Sync Commands - Import Utility  ════════════════════════${RESET}"
  echo "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════════════════════════════════${RESET}"
  echo "${BOLD}${BLUE}════════${RESET} claude mcp add --transport http linear-server https://mcp.linear.app/mcp  ${BOLD}${BLUE}════════${RESET}"
  echo "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════════════════════════════════${RESET}"

  # Display available commands
  display_commands

  # Prompt for import
  if prompt_user; then
    import_commands
  else
    echo ""
    log_info "Import cancelled"
    echo ""
  fi
}

main "$@"
