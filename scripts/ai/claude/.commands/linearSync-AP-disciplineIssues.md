---
description: Sync issues with user's discipline label (not assigned to user)
tags: [linear, sync, issues, active-project, discipline]
---

# linearSync-AP-disciplineIssues: Sync My Discipline Issues

Synchronize issues that have the user's discipline label but are NOT assigned to the user.

This helps users stay aware of work in their discipline that may need attention or context.

## Prerequisites

- Active projects set (`/linearSync-setActiveProject`)
- User discipline defined in `~/.config/ai-context/mcps/linear.claude.md`

## Available Tools

- Linear MCP: `mcp__linear-server__list_issues`, `mcp__linear-server__list_issue_labels`
- File system: Read, Write

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

### Step 1: Read User Info

Read `~/.config/ai-context/mcps/linear.claude.md`:

- Extract user ID
- Extract user discipline (e.g., "Frontend", "Backend", "Fullstack")
- Extract active project IDs

If discipline not set: "Error: Discipline not set in linear.claude.md. Run /linearSync-init to set it."

### Step 2: Verify Label Exists

Call `mcp__linear-server__list_issue_labels(name="{discipline}")` to verify the label exists in Linear.

If label not found, try variations:

- Lowercase: "frontend"
- Capitalized: "Frontend"
- Uppercase: "FRONTEND"

If still not found: "Warning: Label '{discipline}' not found in Linear. No issues will be synced."

### Step 3: For Each Active Project

Loop through each active project:

#### 3a. Fetch Issues with Discipline Label

Call `mcp__linear-server__list_issues(project="{project_id}", label="{discipline}", includeArchived=false, orderBy="updatedAt", limit=250)`

This returns all issues in the project with the discipline label.

#### 3b. Filter Out User's Own Issues

From the results, exclude any issues where:

- assignee.id == user_id

This leaves only issues assigned to OTHER team members in the same discipline.

#### 3c. Write to MyDisciplineIssues.md

Write to `~/.config/ai-context/mcps/projects/{PROJECT_ID}/MyDisciplineIssues.md`:

```markdown
# My Discipline Issues ({Discipline})

Last synced: {current_timestamp}
Project: {project_name}
Discipline: {discipline}

This file shows {discipline} issues NOT assigned to you. Use this to:

- Stay aware of team's work in your discipline
- Identify issues that may need help
- Understand related work that may affect your tasks

---

{For each issue, grouped by status}

## 🟡 In Progress ({count})

### {ISSUE_ID} - {Title}

**Status**: 🟡 {status_name}
**Assignee**: {assignee_name}
**Priority**: {priority_label}
**Updated**: {updatedAt}
**URL**: {linear_url}

{Brief description excerpt (first 200 chars)}

---

### {ISSUE_ID} - {Title}

...

---

## 🔵 In Review ({count})

{Similar format}

---

## 🔴 Todo ({count})

{Similar format}

---

## ⚪️ Backlog ({count})

{Similar format}

---

## 🟢 Recently Completed ({count})

{Show completed issues from last 7 days}

---

## Summary

- Total {discipline} issues (others): {total_count}
- In Progress: {in_progress_count}
- In Review: {review_count}
- Todo: {todo_count}
- Backlog: {backlog_count}

---

_This file is auto-generated. Run /linearSync-AP-disciplineIssues to update._
```

### Step 4: Display Summary

```
Discipline Issues synced successfully!

Discipline: {discipline}

Project: {ProjectName1}
- Issues found: {count}
- In Progress: {in_progress_count}
- In Review: {review_count}
- Todo: {todo_count}
- Backlog: {backlog_count}

File: ~/.config/ai-context/mcps/projects/{id1}/MyDisciplineIssues.md

{Repeat for each active project}

These are {discipline} issues assigned to your teammates. Review them to:
- Stay coordinated with team work
- Identify potential dependencies
- Offer help if needed

Next steps:
- Review MyDisciplineIssues.md for awareness
- Run /linearSync-AP-otherIssues to see other team issues
- Run /linear-NextTask to pick your next task
```

## Issue Grouping

Group issues by status in this priority order:

1. In Progress (most important - active work)
2. In Review (needs attention)
3. Todo (upcoming work)
4. Backlog (future work)
5. Recently Completed (context from past week)

## Description Truncation

For discipline issues, show only:

- First 200 characters of description
- No comments
- No attachments
- Just enough for awareness, not full details

Users can click Linear URL for full details.

## Discipline Label Variations

Common discipline labels:

- Frontend / Front-end / FE
- Backend / Back-end / BE
- Fullstack / Full-stack / Full Stack
- DevOps / Dev-Ops / Infrastructure
- Design / UI / UX / UI/UX
- QA / Testing / Quality
- Product / PM

Try to match user's discipline to existing Linear labels.

## Error Handling

- If label not found: Show warning and create empty file
- If no issues found: "No {discipline} issues found for others in {project_name}"
- If project has no labels: "Warning: Project {project_name} has no labels. Cannot filter by discipline."

## Performance

This command should be relatively fast since it:

- Only fetches issue list (not full details)
- Filters by label (server-side)
- Only writes to 1 file per project

## Expected Output

User will see summary of discipline issues grouped by status for awareness and coordination.
