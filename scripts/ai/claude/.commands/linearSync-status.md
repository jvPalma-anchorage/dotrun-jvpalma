---
description: Comprehensive sync and dashboard summary for daily work pipeline
tags: [linear, sync, status, dashboard, summary]
---

# linearSync-status: Daily Pipeline Status & Sync

Comprehensive command that syncs all Linear data and provides a dashboard-style summary of your work pipeline. Perfect for starting the day.

## What This Command Does

1. **Syncs all data** (in sequence):
   - Team projects overview
   - User projects
   - Active project details
   - My assigned issues

2. **Generates comprehensive dashboard** showing:
   - Active projects overview with progress
   - My issues breakdown by status
   - Priority/urgent items needing attention
   - Overdue tasks
   - Today's focus suggestions
   - Quick stats and velocity

## Prerequisites

- Linear sync system initialized (`/linearSync-init`)
- Active projects set (`/linearSync-setActiveProject`)
- Git repository (optional, for branch context)

## Available Tools

- Linear MCP: `mcp__linear-server__list_projects`, `mcp__linear-server__list_issues`, `mcp__linear-server__get_project`, `mcp__linear-server__get_issue`
- File system: Read, Write, Bash
- Git: Bash (for current branch info)

## Thinking mode

- ultrathink

## Execution Steps

### Step 1: Display Sync Start Banner

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Linear Sync & Status Dashboard
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Syncing all Linear data...

Started at: {current_timestamp}
```

### Step 2: Run All Sync Operations

Execute sync operations in sequence with progress indicators:

#### 2a. Sync Team Projects

```
[1/4] Syncing team projects...
```

Execute the logic from `/linearSync-teamProjects`:

- Call `mcp__linear-server__list_projects` for team
- Write to `~/.config/ai-context/mcps/teamProjects.md`
- Capture result: project count

```
✓ Team projects synced ({count} projects)
```

#### 2b. Sync User Projects

```
[2/4] Syncing user projects...
```

Execute the logic from `/linearSync-userProjects`:

- Call `mcp__linear-server__list_projects(member="me")`
- Write to `~/.config/ai-context/mcps/userProjects.md`
- Capture result: active/completed/paused counts

```
✓ User projects synced ({active_count} active, {completed_count} completed)
```

#### 2c. Sync Active Project Details

```
[3/4] Syncing active project details...
```

Execute the logic from `/linearSync-AP-details`:

- Read active projects from `linear.claude.md`
- For each: call `mcp__linear-server__get_project`
- Write ProjectDetails.md and ProjectStatusUpdates.md
- Capture: changes detected

```
✓ Active project details synced ({count} projects, {changes_count} changes)
```

#### 2d. Sync My Issues

```
[4/4] Syncing my assigned issues...
```

Execute the logic from `/linearSync-AP-myIssues`:

- For each active project: call `mcp__linear-server__list_issues(assignee="me")`
- Write issue folders and index.md files
- Capture: issue counts by status

```
✓ My issues synced ({total_count} issues)

Sync complete! ✨
```

### Step 3: Collect Current Branch Info (Optional)

If in a git repository:

```bash
# Get current branch
git branch --show-current

# Get current branch issue ID (if exists)
# Extract TEAM-123 from branch name
```

This helps show context of current work in the dashboard.

### Step 4: Read and Analyze Synced Data

Read data from synced files to build dashboard:

#### 4a. Read Active Projects Data

For each active project:

- Read `~/.config/ai-context/mcps/projects/{PROJECT_ID}/ProjectDetails.md`
- Extract: name, state, progress, targetDate, lead

#### 4b. Read My Issues Data

For each active project:

- Scan `~/.config/ai-context/mcps/projects/{PROJECT_ID}/MyIssues/*/index.md`
- Parse each issue:
  - Issue ID, title, status, priority, due date
  - Parent relationship
  - Created/updated dates

**Categorize issues by status**:

- 🟡 In Progress
- 🔵 In Review
- 🔴 Todo
- ⚪️ Backlog
- 🟢 Done (for stats only, not displayed in active work)

**Identify special items**:

- 🔥 Urgent priority
- ⚠️ High priority
- ⏰ Overdue (past due date)
- 📅 Due today
- 📆 Due this week

#### 4c. Calculate Statistics

- Total issues assigned
- Issues by status (counts and percentages)
- Issues by priority
- Average time in progress
- Completion velocity (issues completed recently)
- Overdue count
- Issues without due dates

### Step 5: Generate Dashboard Display

Display comprehensive dashboard:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📊 Daily Work Pipeline - {current_date}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{if on a git branch with issue ID}
🌿 Current Branch: {branch_name}
   Working on: {ISSUE_ID} - {issue_title}
   Status: {status_emoji} {status}

{endif}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🎯 Active Projects ({count})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{for each active project}
📁 {ProjectName}
   Progress: [{progress_bar}] {progress}%
   Target: {target_date_formatted} ({days_until} days)
   Lead: {lead_name} {if_lead_is_user}⭐ (You){endif}
   My Issues: {my_issue_count} ({in_progress} in progress, {todo} todo)

{endfor}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🚨 Needs Attention
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{if any urgent or overdue items}

🔥 Urgent & Overdue ({count})
{for each urgent/overdue issue}
   {emoji} {ISSUE_ID} - {title} [{priority}]
       {if overdue}⏰ Overdue by {days} days{endif}
       {if urgent}🔥 Urgent{endif}
       Project: {project_name}

{endfor}

{else}
✅ No urgent or overdue items - great job!
{endif}

{if any due today or this week}

📅 Due Soon ({count})
{for each due soon issue}
   {emoji} {ISSUE_ID} - {title}
       Due: {due_date} {if_today}(Today!){endif}
       Project: {project_name}

{endfor}

{endif}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📋 My Work Pipeline
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟡 In Progress ({count}) {if_count>0}- {percentage}%{endif}
{for each in-progress issue, max 5}
   {ISSUE_ID} - {title_truncated} [{priority}]
   {if has parent}↳ Parent: {parent_id}{endif}

{endfor}
{if more than 5}
   ... and {remaining_count} more
{endif}

🔵 In Review ({count}) {if_count>0}- {percentage}%{endif}
{for each in-review issue, max 5}
   {ISSUE_ID} - {title_truncated} [{priority}]

{endfor}
{if more than 5}
   ... and {remaining_count} more
{endif}

🔴 Todo ({count}) {if_count>0}- {percentage}%{endif}
{for each todo issue, max 5}
   {ISSUE_ID} - {title_truncated} [{priority}]

{endfor}
{if more than 5}
   ... and {remaining_count} more
{endif}

⚪️ Backlog ({count}) {if_count>0}- {percentage}%{endif}
{if count > 0}
   {count} issues in backlog (not shown)
   Run /linear-NextTask to view and select
{endif}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📈 Quick Stats
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total Issues: {total_count}
Active Work:  {in_progress + in_review} issues
Todo:         {todo_count} issues ready to start
Backlog:      {backlog_count} issues

Completion:   {completion_percentage}% ({done_count}/{total_count})
Overdue:      {overdue_count} issues {if>0}⚠️{endif}
No Due Date:  {no_due_date_count} issues

By Priority:
  🔥 Urgent: {urgent_count}
  ⚠️  High:   {high_count}
  📌 Medium: {medium_count}
  ⬇️  Low:    {low_count}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  💡 Today's Focus Suggestions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{generate smart suggestions based on data}

{if in_progress_count > 0}
1. Continue work on in-progress issues:
   {top 2-3 in-progress issues by priority}
{endif}

{if in_review_count > 0}
2. Follow up on issues in review:
   {top 2 in-review issues}
{endif}

{if urgent_count > 0}
3. Address urgent items:
   {urgent issues}
{endif}

{if overdue_count > 0}
4. Clear overdue backlog:
   {top 2 overdue issues}
{endif}

{if no urgent/overdue and todo_count > 0}
5. Start new work from todo:
   {top 2-3 todo issues by priority}
{endif}

{if current branch has issue}
💼 Current: Continue {ISSUE_ID} - {title}
{else}
💼 Pick next task: Run /linear-NextTask
{endif}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔗 Quick Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/linear-NextTask           - Pick your next task interactively
/linearSync-AP-myIssues    - Refresh issue list
/aip                       - Generate PR description
/aic                       - Generate commit message

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Last synced: {timestamp}
Next sync: Run /linearSync-status anytime
```

## Dashboard Formatting Details

### Progress Bar

Show visual progress bar for projects:

```
Progress: [████████░░] 80%
Progress: [███░░░░░░░] 30%
Progress: [██████████] 100%
```

10 blocks total, filled based on percentage.

### Date Formatting

- Today: "Today"
- Tomorrow: "Tomorrow"
- Within 7 days: "In 3 days" or "Mon, Oct 5"
- Past: "2 days ago" or "Overdue by 5 days"
- No date: "Not set"

### Title Truncation

Truncate long titles to fit terminal:

- Max 50 characters for issue titles in lists
- Add "..." if truncated
- Full title available in `/linear-NextTask`

### Emoji Usage

Status emojis:

- 🟡 In Progress
- 🔵 In Review
- 🔴 Todo
- ⚪️ Backlog
- 🟢 Done

Priority/Alert emojis:

- 🔥 Urgent
- ⚠️ High priority
- 📌 Medium priority
- ⬇️ Low priority
- ⏰ Overdue
- 📅 Due today
- 📆 Due this week

## Smart Focus Suggestions Logic

**Priority algorithm**:

1. **Overdue + Urgent** → Highest priority
2. **In Progress + High priority** → Continue momentum
3. **In Review** → Unblock others
4. **Overdue (non-urgent)** → Clear backlog
5. **Due today/this week** → Stay on schedule
6. **Todo + High priority** → Start important work
7. **In Progress (any)** → Finish what you started

**Limit suggestions**:

- Maximum 5 suggestions
- Focus on actionable items
- Group related issues

## Performance Considerations

**Sync operations**:

- Run in sequence (not parallel) to show progress
- Cache API responses where possible
- Limit API calls to what's needed

**Data reading**:

- Read only necessary files
- Parse efficiently (don't read entire files if not needed)
- Cache parsed data during execution

**Dashboard generation**:

- Pre-calculate all stats before display
- Limit displayed items (top 5 per category)
- Truncate long text

## Error Handling

**During sync operations**:

- If team projects sync fails → warn, continue with others
- If user projects sync fails → warn, continue with others
- If active project details sync fails → warn, continue
- If my issues sync fails → warn, show partial dashboard

**During dashboard generation**:

- If data files missing → show what's available
- If no active projects → guide user to set active projects
- If no issues → show encouraging message

**Example partial failure**:

```
⚠️  Warning: Could not sync team projects (Linear API error)
✓ User projects synced (3 active)
✓ Active project details synced (3 projects)
✓ My issues synced (24 issues)

Dashboard showing available data...
```

## First-Time Usage

If Linear sync not initialized:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Linear Sync & Status Dashboard
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  Linear sync system not initialized.

First-time setup required:

1. Initialize Linear sync:
   /linearSync-init

2. Sync your projects:
   /linearSync-userProjects

3. Set active projects:
   /linearSync-setActiveProject

4. Run status again:
   /linearSync-status

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Quick Refresh Mode

To skip sync and just show dashboard (useful for quick checks):

```bash
/linearSync-status --skip-sync
```

This reads existing data without syncing, much faster.

Implementation:

- Check for `--skip-sync` flag in command
- If present, skip Step 2, go directly to Steps 4-5
- Show "(using cached data from {last_sync_time})" in header

## Example Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Linear Sync & Status Dashboard
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Syncing all Linear data...

Started at: 2025-10-02 08:30:15

[1/4] Syncing team projects...
✓ Team projects synced (12 projects)

[2/4] Syncing user projects...
✓ User projects synced (3 active, 2 completed)

[3/4] Syncing active project details...
✓ Active project details synced (3 projects, 1 changes)

[4/4] Syncing my assigned issues...
✓ My issues synced (24 issues)

Sync complete! ✨

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📊 Daily Work Pipeline - Wednesday, Oct 2, 2025
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🌿 Current Branch: team-456/add-policy-form-validation
   Working on: TEAM-456 - Add comprehensive validation to policy forms
   Status: 🟡 In Progress

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🎯 Active Projects (3)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Shared Policies - Improve Web Forms
   Progress: [████████░░] 75%
   Target: Not set
   Lead: João Palma ⭐ (You)
   My Issues: 12 (3 in progress, 4 todo)

📁 Design System: Common Phase Out
   Progress: [███░░░░░░░] 30%
   Target: Jun 30, 2025 (Overdue by 95 days)
   Lead: Sarah Chen
   My Issues: 8 (1 in progress, 2 todo)

📁 Shared Policies - Must fix before enabling externally
   Progress: [██████░░░░] 60%
   Target: Sep 26, 2025 (Overdue by 7 days)
   Lead: Mike Ross
   My Issues: 4 (0 in progress, 1 in review)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🚨 Needs Attention
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔥 Urgent & Overdue (2)
   🔴 TEAM-789 - Fix critical policy save bug [Urgent]
       🔥 Urgent ⏰ Overdue by 3 days
       Project: Shared Policies - Must fix before enabling externally

   🔴 TEAM-801 - Update API rate limiting [High]
       ⏰ Overdue by 1 day
       Project: Design System: Common Phase Out

📅 Due Soon (3)
   🟡 TEAM-456 - Add comprehensive validation to policy forms
       Due: Today!
       Project: Shared Policies - Improve Web Forms

   🔴 TEAM-812 - Implement sub-quorum UI
       Due: Tomorrow
       Project: Shared Policies - Improve Web Forms

   🔴 TEAM-523 - Add E2E tests for policy creation
       Due: In 3 days (Fri, Oct 5)
       Project: Shared Policies - Improve Web Forms

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📋 My Work Pipeline
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟡 In Progress (4) - 17%
   TEAM-456 - Add comprehensive validation to policy forms [High]
   TEAM-478 - Refactor useLatitudeForm hook [Medium]
   TEAM-490 - Update quorum schema validation [Medium]
   TEAM-502 - Add field array soft-append functionality [Low]

🔵 In Review (2) - 8%
   TEAM-445 - Fix form validation timing [High]
   TEAM-467 - Update PolicyForm tests [Medium]

🔴 Todo (6) - 25%
   TEAM-789 - Fix critical policy save bug [Urgent]
   TEAM-801 - Update API rate limiting [High]
   TEAM-812 - Implement sub-quorum UI [High]
   TEAM-523 - Add E2E tests for policy creation [Medium]
   TEAM-534 - Refactor schema consolidation [Medium]
   ... and 1 more

⚪️ Backlog (12) - 50%
   12 issues in backlog (not shown)
   Run /linear-NextTask to view and select

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📈 Quick Stats
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total Issues: 24
Active Work:  6 issues
Todo:         6 issues ready to start
Backlog:      12 issues

Completion:   25% (6/24)
Overdue:      2 issues ⚠️
No Due Date:  10 issues

By Priority:
  🔥 Urgent: 1
  ⚠️  High:   5
  📌 Medium: 12
  ⬇️  Low:    6

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  💡 Today's Focus Suggestions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Clear urgent overdue item:
   TEAM-789 - Fix critical policy save bug

2. Complete today's due issue:
   TEAM-456 - Add comprehensive validation to policy forms

3. Follow up on issues in review:
   TEAM-445 - Fix form validation timing
   TEAM-467 - Update PolicyForm tests

4. Address remaining overdue:
   TEAM-801 - Update API rate limiting

5. Continue momentum on in-progress work:
   TEAM-478 - Refactor useLatitudeForm hook

💼 Current: Continue TEAM-456 - Add comprehensive validation to policy forms

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔗 Quick Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/linear-NextTask           - Pick your next task interactively
/linearSync-AP-myIssues    - Refresh issue list
/aip                       - Generate PR description
/aic                       - Generate commit message

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Last synced: 2025-10-02 08:30:45
Next sync: Run /linearSync-status anytime
```

## Integration with Other Commands

This command is the **central hub** for Linear workflow:

- Use at start of day for complete overview
- Integrates with `/linear-NextTask` for task selection
- Complements `/aic` and `/aip` for git workflows
- Triggers all other linearSync commands automatically

## Expected Output

User receives a comprehensive, visually organized dashboard showing:

- Complete sync status
- Active projects with progress
- Work pipeline breakdown
- Urgent/overdue items
- Smart focus suggestions
- Quick stats
- Fast access to next actions
