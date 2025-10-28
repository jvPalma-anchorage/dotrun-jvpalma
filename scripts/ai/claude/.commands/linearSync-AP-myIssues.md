---
description: Sync user's assigned issues with parent/child nesting support (parallelized)
tags: [linear, sync, issues, active-project, nesting, parallel]
---

# linearSync-AP-myIssues: Sync My Issues (Parallel)

Synchronize all issues assigned to the user for active projects, with support for parent/child issue nesting. Uses parallel sub-agents for faster fetching.

## Prerequisites

- Active projects set (`/linearSync-setActiveProject`)
- `~/.config/ai-context/mcps/linear.claude.md` has active projects defined

## Available Tools

- Linear MCP: `mcp__linear-server__list_issues`, `mcp__linear-server__get_issue`, `mcp__linear-server__list_comments`
- File system: Read, Write, Bash
- Task: For launching parallel sub-agents

## Status Emoji Mapping

Use these emoji prefixes for issue status:

- Backlog / Unstarted: ⚪️
- Todo: 🔴
- In Progress / Started: 🟡
- In Review: 🔵
- Done / Completed: 🟢
- Canceled: ⚫️

## Thinking mode

- ultrathink

## Execution Architecture

This command uses a **two-phase parallel execution model**:

1. **Coordinator Phase** (main command): Lists issues, partitions work, launches agents
2. **Worker Phase** (parallel agents): Each agent fetches details for assigned issues

## Phase 1: Coordinator - List and Partition

### Step 1: Read Active Projects and User Info

Read `~/.config/ai-context/mcps/linear.claude.md`:

- Extract active project IDs
- Extract user ID

If no active projects: "Error: No active projects set. Run /linearSync-setActiveProject first."

### Step 2: Fetch Issue Lists (Lightweight)

For each active project:

Call `mcp__linear-server__list_issues(assignee="me", project="{project_id}", includeArchived=true, limit=250)`

This returns issue metadata (IDs, titles, parent relationships) **without** full details or comments.

### Step 3: Organize and Partition Issues

Parse all issues across all projects and:

1. **Build parent/child tree structure**:
   - Separate top-level issues (parentId = null)
   - Map child issues to parents
   - Maximum nesting depth: 3 levels

2. **Flatten into work list**:
   Create array of all issues to fetch: `[{projectId, issueId, parentPath}, ...]`
   - `parentPath`: For nesting, e.g., `PARENT-123/CHILD-456` or `null` for top-level

3. **Calculate agent count**:

   ```javascript
   TOTAL_ISSUES = issues.length;
   NUM_AGENTS = Math.min(6, Math.max(4, TOTAL_ISSUES));
   ```

   - Minimum 4 agents (even if fewer issues, to ensure parallelism)
   - Maximum 6 agents (to avoid overwhelming API/system)
   - If TOTAL_ISSUES < 4, use TOTAL_ISSUES agents (1 issue per agent)

4. **Partition issues across agents**:
   Distribute issues evenly using round-robin or chunk division:
   ```javascript
   const chunkSize = Math.ceil(TOTAL_ISSUES / NUM_AGENTS);
   const partitions = [];
   for (let i = 0; i < NUM_AGENTS; i++) {
     partitions[i] = issues.slice(i * chunkSize, (i + 1) * chunkSize);
   }
   ```

### Step 4: Launch Parallel Agents

**CRITICAL**: Launch all agents in a **single message** with **multiple Task tool calls** to achieve parallelism.

For each partition (i = 0 to NUM_AGENTS-1), create a Task tool call with:

- **description**: `"Fetch Linear issues batch {i+1}/{NUM_AGENTS}"`
- **subagent_type**: `"general-purpose"`
- **prompt**: See "Worker Agent Prompt Template" below

## Worker Agent Prompt Template

Each worker agent receives this prompt (with partition data injected):

```
You are a worker agent for fetching Linear issue details. Process your assigned batch efficiently.

**Your assigned issues**:
{JSON.stringify(partitions[i], null, 2)}

Example format:
[
  {
    "projectId": "abc123",
    "issueId": "TEAM-456",
    "parentPath": null
  },
  {
    "projectId": "abc123",
    "issueId": "TEAM-457",
    "parentPath": "TEAM-456"
  }
]

**Instructions**:

For each issue in your batch:

1. **Fetch full details**:
   Call `mcp__linear-server__get_issue(id="{issueId}")`

2. **Fetch comments**:
   Call `mcp__linear-server__list_comments(issueId="{issueId}")`

3. **Determine folder path**:
   - If `parentPath` is null:
     `~/.config/ai-context/mcps/projects/{projectId}/MyIssues/{issueId}/`
   - If `parentPath` exists:
     `~/.config/ai-context/mcps/projects/{projectId}/MyIssues/{parentPath}/{issueId}/`

4. **Create folder**:
   Use Bash: `mkdir -p {folderPath}`

5. **Write index.md**:
   Write to `{folderPath}/index.md` with the following format:

---BEGIN TEMPLATE---
# {ISSUE_ID} - {Title}

**Status**: {status_emoji} {status_name}
**Assignee**: {assignee_name}
**Priority**: {priority_label (No priority, Low, Medium, High, Urgent)}
**State Type**: {state_type (backlog, unstarted, started, completed, canceled)}
**Created**: {createdAt}
**Updated**: {updatedAt}
**Due Date**: {dueDate or 'Not set'}

## Description

{description (full markdown)}

## Links

- **Linear**: {url}
{For each additional link}
- **{link_title}**: {link_url}

## Git Branch

- **Suggested**: `{branchName from Linear, or generated: issue-id/slugified-title}`

## Labels

{For each label}
- {label_name}

## Parent/Child Relationships

{If has parent}
- **Parent Issue**: {parent_id} - {parent_title}

{If has children}
- **Sub-issues**:
  - {child_id_1} - {child_title_1}
  - {child_id_2} - {child_title_2}

## Estimate

{estimate (story points or hours)}

## Comments ({comment_count})

{For each comment, newest first}
### {comment_author} - {comment_date}

{comment_body}

---

## Attachments ({attachment_count})

{For each attachment}
- [{attachment_title}]({attachment_url})

---

**Last synced**: {current_timestamp}

_This file is auto-generated. Run /linearSync-AP-myIssues to update._
---END TEMPLATE---

6. **Return completion status**:
   After processing all assigned issues, return a summary:

```

✅ Agent batch {i+1} completed successfully

Processed issues:

- TEAM-123: Success
- TEAM-456: Success
- TEAM-789: Failed (API timeout)

Total: {success_count} successful, {fail_count} failed

```

**Priority Mapping**:
- 0: No priority
- 1: Urgent
- 2: High
- 3: Medium (Normal)
- 4: Low

**Branch Name Generation**:
If Linear provides `branchName`, use it. Otherwise:
1. Take issue ID: "TEAM-123"
2. Slugify title: "Fix Login Bug" → "fix-login-bug"
3. Combine: "team-123/fix-login-bug"
4. Max length: 50 characters

**Error handling**:
- If issue fetch fails: Log warning, continue with next issue
- If folder creation fails: Log error, continue with next issue
- Always complete your batch and report status
```

## Phase 2: Coordinator - Aggregate Results

After all agents complete:

### Step 5: Collect Agent Results

Wait for all agents to return (Claude Code handles this automatically).

Parse each agent's response to extract:

- Successful issue IDs
- Failed issue IDs
- Any warnings/errors

### Step 6: Display Comprehensive Summary

```
🎯 My Issues synced successfully!

Project: {ProjectName1}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Statistics:
  • Total issues: {count}
  • Top-level: {parent_count}
  • Sub-issues: {child_count}
  • Agents used: {NUM_AGENTS}

📈 Status breakdown:
  🟡 In Progress: {in_progress_count}
  🔵 In Review: {review_count}
  🔴 Todo: {todo_count}
  ⚪️ Backlog: {backlog_count}
  🟢 Done: {done_count}

📁 Path: ~/.config/ai-context/mcps/projects/{id1}/MyIssues/

{Repeat for each active project}

⚠️ Warnings: {If any failures occurred, list them}

✨ Next steps:
  • Run /linear-NextTask to select your next task
  • Review issues in ~/.config/ai-context/mcps/projects/{id}/MyIssues/
```

## Performance Characteristics

- **Sequential (old)**: ~30-60s for 20 issues (1.5-3s per issue)
- **Parallel (new)**: ~10-15s for 20 issues with 4-6 agents (4x-6x speedup)

Bottlenecks:

- Linear API rate limits (if hit, agents will queue naturally)
- File I/O (minimal compared to network)

## Error Handling

- **No issues found**: "No issues assigned to you in {project_name}"
- **Issue fetch fails**: Worker logs warning, continues
- **Agent fails completely**: Coordinator reports partial success
- **Folder creation fails**: Worker logs error, continues
- **Nesting depth > 3**: Worker logs warning, caps at 3 levels

## Example Execution Flow

```
User runs: /linearSync-AP-myIssues

[Coordinator starts]
✓ Read active projects: 2 projects
✓ Fetched issue lists: 23 issues total
✓ Built parent/child tree: 18 top-level, 5 children
✓ Calculated agents: 6 agents (23 issues ÷ 6 ≈ 4 per agent)
✓ Partitioned work:
  - Agent 1: 4 issues
  - Agent 2: 4 issues
  - Agent 3: 4 issues
  - Agent 4: 4 issues
  - Agent 5: 4 issues
  - Agent 6: 3 issues

🚀 Launching 6 parallel agents...

[Agents work in parallel - Claude shows all 6 running]

[After ~12 seconds, all agents return]

✅ Agent 1: 4/4 successful
✅ Agent 2: 4/4 successful
✅ Agent 3: 4/4 successful
✅ Agent 4: 3/4 successful (1 timeout)
✅ Agent 5: 4/4 successful
✅ Agent 6: 3/3 successful

[Coordinator aggregates and displays summary]

🎯 Sync complete: 22/23 issues synced successfully
```

## Optimization Tips

1. **Agent count tuning**:
   - For < 10 issues: 4 agents is optimal
   - For 10-30 issues: 4-6 agents
   - For > 30 issues: Max 6 agents (diminishing returns)

2. **API efficiency**:
   - `list_issues` is lightweight (no comments/attachments)
   - `get_issue` + `list_comments` are heavy (per-issue)
   - Parallelizing the heavy calls provides maximum benefit

3. **Partition strategy**:
   - Round-robin ensures even distribution
   - Consider grouping by project if multiple projects (future optimization)

## Future Enhancements

- **Incremental sync**: Only fetch changed issues (requires timestamp tracking)
- **Smart partitioning**: Group by project to reduce context switching
- **Progress indicators**: Real-time agent progress updates
- **Retry logic**: Automatic retry for failed issues
- **Archive cleanup**: Remove issues no longer assigned to user
