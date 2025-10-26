#!/usr/bin/env bash
### DOC
# Enhanced git/yadm status with categorization and command generation
### DOC
#
# Displays git or yadm status with colored output, categorized by staging status,
# and optionally generates commands for batch operations.
#
# Usage:
#   dr gitStatus [options] [command]
#
# Options:
#   -h              Show paths relative to $HOME instead of current directory
#   g<command>      Use git with specified command (gdiff, gadd, grm, gco)
#   y<command>      Use yadm with specified command (ydiff, yadd, yrm, yco)
#
# Commands:
#   diff            Generate diff commands for all changed files
#   add             Generate add commands for unstaged/untracked files
#   rm              Generate rm commands for staged/unstaged files
#   co              Generate checkout commands to discard changes
#
# Examples:
#   dr gitStatus              # Show status
#   dr gitStatus gdiff        # Show diff commands
#   dr gitStatus yadd -h      # Show yadm add commands with home paths
#
### DOC
set -euo pipefail

# Load loadHelpers function for dual-mode execution
[[ -n "${DR_LOAD_HELPERS:-}" ]] && source "$DR_LOAD_HELPERS"

# Load required helper
loadHelpers global/colors

gitStatus() {
  clear
  local cmd=""
  use_home_path=false

  local git_tool="git"

  # Parse arguments
  for arg in "$@"; do
    case "$arg" in
      -h)
        use_home_path=true
        ;;
      g*)
        git_tool="git"
        cmd="${arg#g}" # Remove 'g' prefix
        ;;
      y*)
        git_tool="yadm"
        cmd="${arg#y}" # Remove 'y' prefix
        ;;
      *)
        # Handle commands without prefix (assume git)
        if [[ "$arg" =~ ^(add|diff|rm|co)$ ]]; then
          cmd="$arg"
        fi
        ;;
    esac
  done

  # Get git status and extract modified files
  local status_output
  status_output=$($git_tool status --porcelain)

  # Get git repository root and current directory for relative path calculation
  local git_root
  git_root=$($git_tool rev-parse --show-toplevel)
  local current_dir
  current_dir=$(pwd)

  # Arrays to store files by category
  local staged_new=()
  local staged_modified=()
  local staged_deleted=()
  local unstaged_new=()
  local unstaged_modified=()
  local unstaged_deleted=()
  local untracked=()
  local conflict_both_modified=()
  local conflict_both_added=()
  local conflict_both_deleted=()
  local conflict_added_by_us=()
  local conflict_added_by_them=()
  local conflict_deleted_by_us=()
  local conflict_deleted_by_them=()

  # Process each line and categorize files
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      local status_code="${line:0:2}"
      local filepath="${line:3}"
      local full_path="$filepath"

      # Handle path based on -h flag
      if [[ "$use_home_path" == true ]]; then
        # For -h flag: convert to absolute path and replace $HOME with ~/
        if [[ "$filepath" = /* ]]; then
          # Already absolute path (common with yadm)
          full_path=$(echo "$filepath" | sed "s|^$HOME|~|")
        else
          # Relative path, make it absolute first
          local absolute_file_path="$git_root/$filepath"
          full_path=$(echo "$absolute_file_path" | sed "s|^$HOME|~|")
        fi
      else
        # Default: show path relative to current working directory
        local absolute_file_path="$git_root/$filepath"
        # Try realpath with --relative-to first (Linux), fallback to python (cross-platform)
        if full_path=$(realpath --relative-to="$current_dir" "$absolute_file_path" 2>/dev/null); then
          : # full_path is already set
        else
          # Fallback to python for cross-platform relative path calculation
          full_path=$(python3 -c "import os; print(os.path.relpath('$absolute_file_path', '$current_dir'))" 2>/dev/null || echo "$filepath")
        fi
      fi

      # Categorize files based on status code
      case "$status_code" in
        "A ")
          staged_new+=("$full_path")
          ;;
        "M ")
          staged_modified+=("$full_path")
          ;;
        "D ")
          staged_deleted+=("$full_path")
          ;;
        " A")
          unstaged_new+=("$full_path")
          ;;
        " M")
          unstaged_modified+=("$full_path")
          ;;
        " D")
          unstaged_deleted+=("$full_path")
          ;;
        "MM")
          # File is both staged AND has unstaged changes
          staged_modified+=("$full_path")
          unstaged_modified+=("$full_path")
          ;;
        "AM")
          # File is staged as new AND has unstaged modifications
          staged_new+=("$full_path")
          unstaged_modified+=("$full_path")
          ;;
        "AD")
          # File is staged as new AND has unstaged deletion
          staged_new+=("$full_path")
          unstaged_deleted+=("$full_path")
          ;;
        "??")
          untracked+=("$full_path")
          ;;
        # Merge conflict status codes
        "UU")
          conflict_both_modified+=("$full_path")
          ;;
        "AA")
          conflict_both_added+=("$full_path")
          ;;
        "DD")
          conflict_both_deleted+=("$full_path")
          ;;
        "AU")
          conflict_added_by_us+=("$full_path")
          ;;
        "UA")
          conflict_added_by_them+=("$full_path")
          ;;
        "DU")
          conflict_deleted_by_us+=("$full_path")
          ;;
        "UD")
          conflict_deleted_by_them+=("$full_path")
          ;;
      esac
    fi
  done <<<"$status_output"

  # Helper function to format file output based on command and staging status
  format_file_output() {
    local file="$1"
    local color="$2"
    local staging_status="$3" # "staged", "unstaged", "untracked", or "conflict"

    case "$cmd" in
      "diff")
        case "$staging_status" in
          "staged")
            echo "$CYAN$git_tool diff --cached $NC$color$file$NC"
            ;;
          "unstaged")
            echo "$CYAN$git_tool diff $NC$color$file$NC"
            ;;
          "untracked")
            # For untracked files, diff doesn't work, show file content instead
            echo "${CYAN}cat $NC$color$file$NC"
            ;;
          "conflict")
            # For conflicts, show both sides
            echo "$CYAN$git_tool diff $NC$color$file$NC$CYAN  # Shows conflict markers$NC"
            ;;
        esac
        ;;
      "add")
        case "$staging_status" in
          "unstaged" | "untracked")
            echo "$CYAN$git_tool add $NC$color$file$NC"
            ;;
          "conflict")
            echo "$CYAN$git_tool add $NC$color$file$NC$CYAN  # Mark as resolved$NC"
            ;;
        esac
        ;;
      "rm")
        case "$staging_status" in
          "staged")
            echo "$CYAN$git_tool rm $NC$color$file$NC$CYAN --cached$NC"
            ;;
          "unstaged" | "untracked")
            echo "rm $NC$color$file$NC"
            ;;
          "conflict")
            echo "$CYAN$git_tool rm $NC$color$file$NC"
            ;;
        esac
        ;;
      "co")
        case "$staging_status" in
          "staged")
            echo "$CYAN$git_tool co $NC$color$file$NC$CYAN"
            ;;
          "unstaged" | "untracked")
            echo "$CYAN$git_tool co $NC$color$file$NC"
            ;;
          "conflict")
            echo "$CYAN$git_tool co --ours $NC$color$file$NC$CYAN  # or --theirs$NC"
            ;;
        esac
        ;;
      *)
        echo "$color$file$NC"
        ;;
    esac
  }

  # Output grouped results
  local has_changes=false

  # Conflicted files (show first, most important)
  local has_conflicts=false
  if [[ ${#conflict_both_modified[@]} -gt 0 || ${#conflict_both_added[@]} -gt 0 || ${#conflict_both_deleted[@]} -gt 0 ||
    ${#conflict_added_by_us[@]} -gt 0 || ${#conflict_added_by_them[@]} -gt 0 ||
    ${#conflict_deleted_by_us[@]} -gt 0 || ${#conflict_deleted_by_them[@]} -gt 0 ]]; then
    echo "${RED}⚠️  Conflicted files (resolve these first):${NC}"
    has_changes=true
    has_conflicts=true

    # Both modified
    for file in "${conflict_both_modified[@]+"${conflict_both_modified[@]}"}"; do
      if [[ -n "$cmd" ]]; then
        printf "\t%s\n" "$(format_file_output "$file" "$RED" "conflict")"
      else
        printf "\t%s:   %s\n" "${RED}both modified${NC}" "$(format_file_output "$file" "$RED" "conflict")"
      fi
    done

    # Both added
    for file in "${conflict_both_added[@]+"${conflict_both_added[@]}"}"; do
      if [[ -n "$cmd" ]]; then
        printf "\t%s\n" "$(format_file_output "$file" "$RED" "conflict")"
      else
        printf "\t%s:      %s\n" "${RED}both added${NC}" "$(format_file_output "$file" "$RED" "conflict")"
      fi
    done

    # Both deleted
    for file in "${conflict_both_deleted[@]+"${conflict_both_deleted[@]}"}"; do
      if [[ -n "$cmd" ]]; then
        printf "\t%s\n" "$(format_file_output "$file" "$RED" "conflict")"
      else
        printf "\t%s:    %s\n" "${RED}both deleted${NC}" "$(format_file_output "$file" "$RED" "conflict")"
      fi
    done

    # Added by us
    for file in "${conflict_added_by_us[@]+"${conflict_added_by_us[@]}"}"; do
      if [[ -n "$cmd" ]]; then
        printf "\t%s\n" "$(format_file_output "$file" "$RED" "conflict")"
      else
        printf "\t%s:  %s\n" "${RED}added by us${NC}" "$(format_file_output "$file" "$RED" "conflict")"
      fi
    done

    # Added by them
    for file in "${conflict_added_by_them[@]+"${conflict_added_by_them[@]}"}"; do
      if [[ -n "$cmd" ]]; then
        printf "\t%s\n" "$(format_file_output "$file" "$RED" "conflict")"
      else
        printf "\t%s: %s\n" "${RED}added by them${NC}" "$(format_file_output "$file" "$RED" "conflict")"
      fi
    done

    # Deleted by us
    for file in "${conflict_deleted_by_us[@]+"${conflict_deleted_by_us[@]}"}"; do
      if [[ -n "$cmd" ]]; then
        printf "\t%s\n" "$(format_file_output "$file" "$RED" "conflict")"
      else
        printf "\t%s: %s\n" "${RED}deleted by us${NC}" "$(format_file_output "$file" "$RED" "conflict")"
      fi
    done

    # Deleted by them
    for file in "${conflict_deleted_by_them[@]+"${conflict_deleted_by_them[@]}"}"; do
      if [[ -n "$cmd" ]]; then
        printf "\t%s\n" "$(format_file_output "$file" "$RED" "conflict")"
      else
        printf "\t%s: %s\n" "${RED}deleted by them${NC}" "$(format_file_output "$file" "$RED" "conflict")"
      fi
    done

    echo
  fi

  # Changes to be committed
  if [[ ${#staged_new[@]} -gt 0 || ${#staged_modified[@]} -gt 0 || ${#staged_deleted[@]} -gt 0 ]]; then
    echo "Changes to be committed:"
    has_changes=true

    # New files (green)
    for file in "${staged_new[@]+"${staged_new[@]}"}"; do
      if [[ -n "$cmd" ]]; then
        printf "\t%s\n" "$(format_file_output "$file" "$GREEN" "staged")"
      else
        printf "\t%s:   %s\n" "${GREEN}new file${NC}" "$(format_file_output "$file" "$GREEN" "staged")"
      fi
    done

    # Modified files (yellow)
    for file in "${staged_modified[@]+"${staged_modified[@]}"}"; do
      if [[ -n "$cmd" ]]; then
        printf "\t%s\n" "$(format_file_output "$file" "$YELLOW" "staged")"
      else
        printf "\t%s:   %s\n" "${YELLOW}modified${NC}" "$(format_file_output "$file" "$YELLOW" "staged")"
      fi
    done

    # Deleted files (red)
    for file in "${staged_deleted[@]+"${staged_deleted[@]}"}"; do
      if [[ -n "$cmd" ]]; then
        printf "\t%s\n" "$(format_file_output "$file" "$RED" "staged")"
      else
        printf "\t%s:    %s\n" "${RED}deleted${NC}" "$(format_file_output "$file" "$RED" "staged")"
      fi
    done

    echo
  fi

  # Changes not staged for commit
  if [[ ${#unstaged_new[@]} -gt 0 || ${#unstaged_modified[@]} -gt 0 || ${#unstaged_deleted[@]} -gt 0 ]]; then
    echo "Changes not staged for commit:"
    has_changes=true

    # New files (green)
    for file in "${unstaged_new[@]+"${unstaged_new[@]}"}"; do
      if [[ -n "$cmd" ]]; then
        printf "\t%s\n" "$(format_file_output "$file" "$GREEN" "unstaged")"
      else
        printf "\t%s:   %s\n" "${GREEN}new file${NC}" "$(format_file_output "$file" "$GREEN" "unstaged")"
      fi
    done

    # Modified files (yellow)
    for file in "${unstaged_modified[@]+"${unstaged_modified[@]}"}"; do
      if [[ -n "$cmd" ]]; then
        printf "\t%s\n" "$(format_file_output "$file" "$YELLOW" "unstaged")"
      else
        printf "\t%s:   %s\n" "${YELLOW}modified${NC}" "$(format_file_output "$file" "$YELLOW" "unstaged")"
      fi
    done

    # Deleted files (red)
    for file in "${unstaged_deleted[@]+"${unstaged_deleted[@]}"}"; do
      if [[ -n "$cmd" ]]; then
        printf "\t%s\n" "$(format_file_output "$file" "$RED" "unstaged")"
      else
        printf "\t%s:    %s\n" "${RED}deleted${NC}" "$(format_file_output "$file" "$RED" "unstaged")"
      fi
    done

    echo
  fi

  # Untracked files
  if [[ ${#untracked[@]} -gt 0 ]]; then
    echo "Untracked files:"
    has_changes=true

    # Untracked files (cyan)
    for file in "${untracked[@]+"${untracked[@]}"}"; do
      printf "\t%s\n" "$(format_file_output "$file" "$CYAN" "untracked")"
    done

    echo
  fi

  # If no changes, show a message
  if [[ "$has_changes" == false ]]; then
    echo "✅ No changes detected."
  fi
}

# If script is called directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  gitStatus "$@"
fi
