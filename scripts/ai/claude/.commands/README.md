# Claude Code Command Management

This directory contains Claude Code slash commands that can be imported into the user's global commands directory.

## Usage

Run the import script:

```bash
dr linearCommands
```

Or directly:

```bash
bash scripts/ai/claude/linearCommands.sh
```

## How to Reuse This Pattern

The `linearCommands.sh` script is designed to be generic and reusable. Here's how to adapt it for other command sets:

### 1. **Command Files Format**

Commands should be markdown files with YAML front matter:

```markdown
---
description: Your command description here
tags: [optional, tags]
---

# Command Title

Command content...
```

### 2. **Customization Points**

Edit these sections in your copy of the script:

```bash
# Pattern to match your command files
readonly COMMAND_FILE_PATTERN="yourPrefix-*.md"

# Custom display order (hardcoded for your specific workflow)
# Use "---" entries for visual separators between command groups
readonly DISPLAY_ORDER=(
  "yourPrefix-init"
  "---"
  "yourPrefix-setup"
  "yourPrefix-deploy"
  "---"
  "yourPrefix-status"
  # ... add your commands in desired order
)

# Update the header text
echo "${BOLD}${BLUE}  Your Custom Commands - Import Utility${RESET}"
```

### 3. **Generic Functions (No Changes Needed)**

These functions work for any command set:

- `extract_description()` - Extracts description from YAML front matter
- `display_command()` - Shows command with colors
- `display_commands()` - Loops through and displays all commands
- `import_commands()` - Copies commands to ~/.claude/commands
- `prompt_user()` - Interactive confirmation

### 4. **Key Design Decisions**

**YAML Parsing:**
- Uses `yq` if available (most robust)
- Falls back to `awk` (works everywhere)

**Error Handling:**
- Compatible with `set -euo pipefail`
- Uses `found_count=$((found_count + 1))` instead of `((found_count++))` to avoid exit on first increment

**Display Order:**
- Hardcoded array for explicit control
- Easy to modify for different workflows

## Example: Creating a New Command Set

```bash
# 1. Copy the script
cp scripts/ai/claude/linearCommands.sh scripts/ai/claude/gitCommands.sh

# 2. Edit the COMMAND_FILE_PATTERN
readonly COMMAND_FILE_PATTERN="git-*.md"

# 3. Update DISPLAY_ORDER
readonly DISPLAY_ORDER=(
  "git-init"
  "git-commit"
  "git-push"
)

# 4. Create .commands directory
mkdir -p scripts/ai/claude/.commands

# 5. Add your command files
cat > scripts/ai/claude/.commands/git-init.md << 'EOF'
---
description: Initialize a new git repository
---

# git-init

Initialize a new git repository with best practices...
EOF
```

## Script Features

- ✅ **Color-coded output** using dotrun's color helpers
- ✅ **Progress tracking** with counters and status messages
- ✅ **Safe imports** - skips existing files
- ✅ **Error handling** - validates directories and files
- ✅ **Generic design** - reusable for any command set
- ✅ **YAML parsing** - with fallback for systems without yq
- ✅ **Custom ordering** - explicit control over display sequence
- ✅ **Visual separators** - use `"---"` entries to group related commands

## Troubleshooting

**Commands not showing up?**
- Check that files exist in `.commands/` directory
- Verify YAML front matter is properly formatted
- Ensure filenames match the DISPLAY_ORDER entries

**Import failing?**
- Check permissions on `~/.claude/commands`
- Verify source files are readable

**Wrong order?**
- Update the `DISPLAY_ORDER` array in the script
