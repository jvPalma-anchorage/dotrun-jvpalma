---
description: Interactive task picker with tree view and branch name suggestion
tags: [linear, interactive, tasks, workflow]
---

# linear-NextTask: Pick Your Next Task

Interactive command to browse your issues in a tree view and select your next task with branch name suggestion.

## Prerequisites

- Active project synced with issues (`/linearSync-AP-myIssues`)
- At least one active project with synced issues

## Available Tools

- File system: Read, Glob

## Status Emoji Mapping

- Backlog / Unstarted: ⚪️
- Todo: 🔴
- In Progress / Started: 🟡
- In Review: 🔵
- Done / Completed: 🟢
- Canceled: ⚫️

## Thinking mode

- ultrathink

## Execution Steps

### Step 1: Read Active Projects

Read `~/.config/ai-context/mcps/linear.claude.md` and extract active project IDs.

If multiple active projects, use the FIRST one as default, but show option to select:

```
You have {count} active projects:
1. {ProjectName1}
2. {ProjectName2}

Using: {ProjectName1} (default)

To view tasks from another project, specify which one or re-run /linearSync-setActiveProject.
```

### Step 2: Scan Issue Folders

Scan the folder structure: `~/.config/ai-context/mcps/projects/{PROJECT_ID}/MyIssues/`

Use Glob or recursive directory listing to find all `index.md` files:

```
MyIssues/ISSUE-123/index.md
MyIssues/ISSUE-124/index.md
MyIssues/ISSUE-125/CHILD-456/index.md
MyIssues/ISSUE-125/CHILD-457/index.md
```

### Step 3: Parse Issue Files

For each `index.md` file:

1. Read the file content
2. Extract from the markdown:
   - Issue ID (from heading: `# ISSUE-123 - Title`)
   - Title
   - Status emoji and name (from **Status** line)
   - Priority (from **Priority** line)
   - Git Branch suggestion (from **Git Branch** section)
   - Parent relationship (from folder structure)

3. Determine nesting level:
   - Top-level: `MyIssues/{ISSUE_ID}/index.md`
   - Child: `MyIssues/{PARENT_ID}/{CHILD_ID}/index.md`
   - Sub-child: `MyIssues/{PARENT_ID}/{CHILD_ID}/{SUBCHILD_ID}/index.md`

### Step 4: Build Tree Structure

Organize issues by:

1. **Status groups** (in this order):
   - In Progress (🟡)
   - In Review (🔵)
   - Todo (🔴)
   - Backlog (⚪️)

2. **Within each status group**:
   - Top-level issues first
   - Children indented under parent
   - Sub-children further indented

3. **Number sequentially** across all groups (1, 2, 3, ... N)

### Step 5: Display Tree View

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Next Tasks for {ProjectName}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟡 In Progress ({count})

1. TEAM-123 - Implement authentication flow [High]
   └── 2. TEAM-124 - Add JWT validation [Medium]

🔵 In Review ({count})

3. TEAM-125 - Fix login bug [Urgent]

🔴 Todo ({count})

4. TEAM-126 - Add user profile page [Medium]
5. TEAM-127 - Integrate payment gateway [High]
   └── 6. TEAM-128 - Setup Stripe webhook [Medium]
   └── 7. TEAM-129 - Add payment error handling [Low]

⚪️ Backlog ({count})

8. TEAM-130 - Refactor API endpoints [Low]
9. TEAM-131 - Add unit tests for auth module [Medium]
10. TEAM-132 - Performance optimization [Low]
    └── 11. TEAM-133 - Database query optimization [Medium]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: {count} issues | Type a number (1-{count}) to view details
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Enter task number (or 'q' to quit):
```

**Tree formatting rules**:

- Use `└──` for child issues
- Indent children by 3 spaces
- Show priority in brackets: `[High]`, `[Medium]`, `[Low]`, `[Urgent]`
- Number continuously across all groups

### Step 6: Wait for User Input

Pause and wait for user to enter a number.

Validate:

- Number is between 1 and {count}
- Input is valid

If 'q' or 'quit', exit.

### Step 7: Display Selected Task Details

Read the full `index.md` file for the selected task.

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Task Details: {ISSUE_ID}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title: {Full Title}
Status: {emoji} {status_name}
Priority: {priority_label}
Assignee: {assignee_name}
Due Date: {dueDate or 'Not set'}

{If has parent}
Parent Issue: {parent_id} - {parent_title}

{If has children}
Sub-issues:
- {child_id_1} - {child_title_1}
- {child_id_2} - {child_title_2}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Description
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{Full description content}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Links
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- Linear: {url}
{Additional links}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Git Branch
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Suggested branch name:
  {branch_name}

Create branch with:
  git checkout -b {branch_name}

{If in a git repo}
Current branch: {current_git_branch}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Comments ({comment_count})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{For each comment}

{author} - {date}:
{comment_body}

---

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ready to start?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Would you like to:
1. Create the branch and start working (git checkout -b {branch_name})
2. Just copy the branch name to clipboard
3. Go back to task list
4. Exit

Enter choice (1-4):
```

### Step 8: Handle User Action Choice

Based on user's choice:

**Choice 1**: Run `git checkout -b {branch_name}` using Bash tool

- Check if already in git repo
- Create and switch to new branch
- Confirm success

**Choice 2**: Display branch name for manual copy

```
Branch name: {branch_name}

Copy this and create the branch manually.
```

**Choice 3**: Return to Step 5 (show task list again)

**Choice 4**: Exit

## Branch Name Generation

Read from the issue's **Git Branch** section.

If Linear provided a branch name, use it.

If not, generate:

1. Get issue ID: "TEAM-123"
2. Slugify title:
   - Lowercase
   - Replace spaces with hyphens
   - Remove special characters
   - Max 40 characters
   - Example: "implement-authentication-flow"
3. Combine: "team-123/implement-authentication-flow"

## Error Handling

- If no issues found: "No issues synced. Run /linearSync-AP-myIssues first."
- If no active project: "No active project set. Run /linearSync-setActiveProject first."
- If git checkout fails: "Error creating branch. Check git status."
- If invalid input: "Invalid input. Please enter a number between 1 and {count}."

## Priority Display

Show priority badges in tree view:

- `[Urgent]` - Red/bold if terminal supports
- `[High]` - Orange if terminal supports
- `[Medium]` - Normal
- `[Low]` - Gray if terminal supports
- No badge if no priority set

## Status Group Order

Always show in this order (even if empty):

1. 🟡 In Progress (highest priority - work in flight)
2. 🔵 In Review (needs attention)
3. 🔴 Todo (ready to start)
4. ⚪️ Backlog (future work)

Don't show 🟢 Done issues in NextTask (they're done!).

## Multiple Active Projects

If user has multiple active projects, show tasks from the FIRST active project by default.

To switch projects, user should either:

- Re-run /linearSync-setActiveProject to change order
- Manually specify project in future enhancement

## Expected Output

User will see an interactive, visually organized task list with tree structure, then detailed view of selected task with branch name and action options.
