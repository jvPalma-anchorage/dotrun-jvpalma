---
description: Sync all other team issues (not assigned to user, not in user's discipline)
tags: [linear, sync, issues, active-project, team]
---

# linearSync-AP-otherIssues: Sync Other Team Issues

Synchronize all other team issues that are:

- NOT assigned to the user
- NOT labeled with the user's discipline

This provides full team visibility beyond the user's immediate scope.

## Prerequisites

- Active projects set (`/linearSync-setActiveProject`)
- User info defined in `~/.config/ai-context/mcps/linear.claude.md`

## Available Tools

- Linear MCP: `mcp__linear-server__list_issues`
- File system: Read, Write

## Status Emoji Mapping

- Backlog / Unstarted: ⚪️
- Todo: 🔴
- In Progress / Started: 🟡
- In Review: 🔵
- Done / Completed: 🟢
- Canceled: ⚫️

## Execution Steps

### Step 1: Read User Info

Read `~/.config/ai-context/mcps/linear.claude.md`:

- Extract user ID
- Extract user discipline
- Extract active project IDs

### Step 2: For Each Active Project

Loop through each active project:

#### 2a. Fetch All Project Issues

Call `mcp__linear-server__list_issues(project="{project_id}", includeArchived=false, orderBy="updatedAt", limit=250)`

This returns ALL issues in the project.

#### 2b. Filter Issues

Exclude issues where:

1. assignee.id == user_id (user's own issues)
2. labels include user's discipline (discipline issues)

What remains are "other" issues - work outside the user's immediate scope but still relevant for team context.

#### 2c. Group by Labels/Categories

If possible, group issues by:

- Other disciplines (Backend, Design, DevOps, etc.)
- Feature areas
- No labels (unlabeled issues)

#### 2d. Write to OtherIssuesIssues.md

Write to `~/.config/ai-context/mcps/projects/{PROJECT_ID}/OtherIssuesIssues.md`:

```markdown
# Other Team Issues

Last synced: {current_timestamp}
Project: {project_name}

This file shows team issues outside your discipline and assignments. Use this to:

- Maintain full team context
- Understand cross-functional work
- Identify potential blockers or dependencies
- Coordinate with other disciplines

---

{Group by discipline/label if available}

## Backend Issues ({count})

### {ISSUE_ID} - {Title}

**Status**: {emoji} {status_name}
**Assignee**: {assignee_name or 'Unassigned'}
**Priority**: {priority_label}
**Labels**: {label1, label2, label3}
**Updated**: {updatedAt}
**URL**: {linear_url}

---

## Design Issues ({count})

### {ISSUE_ID} - {Title}

**Status**: {emoji} {status_name}
**Assignee**: {assignee_name}
**Priority**: {priority_label}
**Labels**: {labels}
**Updated**: {updatedAt}
**URL**: {linear_url}

---

## DevOps Issues ({count})

{Similar format}

---

## Unlabeled Issues ({count})

{Issues without discipline labels}

---

## Status Summary

- 🟡 In Progress: {in_progress_count}
- 🔵 In Review: {review_count}
- 🔴 Todo: {todo_count}
- ⚪️ Backlog: {backlog_count}
- 🟢 Done (last 7 days): {done_count}

## Assignee Summary

{For each assignee}

- {assignee_name}: {issue_count} issues

---

_This file is auto-generated. Run /linearSync-AP-otherIssues to update._
```

### Step 3: Display Summary

```
Other Team Issues synced successfully!

Project: {ProjectName1}
- Total other issues: {count}
- By discipline:
  - Backend: {backend_count}
  - Design: {design_count}
  - DevOps: {devops_count}
  - Unlabeled: {unlabeled_count}
- By status:
  🟡 In Progress: {in_progress_count}
  🔵 In Review: {review_count}
  🔴 Todo: {todo_count}
  ⚪️ Backlog: {backlog_count}

File: ~/.config/ai-context/mcps/projects/{id1}/OtherIssuesIssues.md

{Repeat for each active project}

Review for:
- Cross-team dependencies
- Potential collaboration opportunities
- Full project context

Next steps:
- Review OtherIssuesIssues.md for team awareness
- Run /linear-NextTask to pick your next task
```

## Grouping Strategy

**Primary grouping: By Label (Discipline)**

If an issue has multiple labels, prioritize discipline labels:

1. Backend
2. Frontend
3. Design
4. DevOps
5. QA
6. Product
7. Other labels
8. Unlabeled

**Secondary sorting: By Status**
Within each group, sort by:

1. In Progress (most urgent)
2. In Review
3. Todo
4. Backlog

## Description Handling

For other issues, show minimal detail:

- Issue ID and Title
- Status and assignee
- Labels for categorization
- Linear URL for full details

Do NOT include:

- Full descriptions
- Comments
- Attachments

This keeps the file manageable and focused on awareness, not deep detail.

## Filtering Logic

```
ALL project issues
  MINUS user's assigned issues (from myIssues)
  MINUS user's discipline issues (from disciplineIssues)
  = Other team issues
```

## Team Coordination Use Cases

This file helps users:

1. **Identify blockers**: See if dependent work is in progress
2. **Avoid duplication**: Check if similar work exists
3. **Offer help**: Identify issues that might benefit from expertise
4. **Stay informed**: Maintain project context beyond own scope
5. **Coordinate releases**: See what else is shipping in the same timeframe

## Error Handling

- If no other issues found: "No other team issues in {project_name}. All work is either assigned to you or in your discipline."
- If project too large (>250 issues): "Warning: Project has >250 issues. Showing first 250 ordered by update date."

## Performance

This command may be slower for large projects with many issues. Consider:

- Pagination if issue count > 250
- Caching to avoid refetching unchanged data
- Incremental updates (only fetch issues updated since last sync)

For MVP: Accept slower performance for comprehensiveness.

## Expected Output

User will see a comprehensive view of all team work outside their immediate scope, organized by discipline and status.
