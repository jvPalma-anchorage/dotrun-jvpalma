---
description: Sync user's Linear projects to userProjects.md
tags: [linear, sync, projects]
---

# linearSync-userProjects: Sync User Projects

Synchronize all projects where the user is a member to `~/.config/ai-context/mcps/userProjects.md`.

## Prerequisites

- Linear sync system initialized (`/linearSync-init`)
- `~/.config/ai-context/mcps/linear.claude.md` exists

## Available Tools

- Linear MCP: `mcp__linear-server__list_projects`, `mcp__linear-server__get_project`
- File system: Read, Write

## Thinking mode

- ultrathink

## Execution Steps

### Step 1: Verify Prerequisites

Check if `~/.config/ai-context/mcps/linear.claude.md` exists.
If not, display error: "Error: Linear sync not initialized. Run /linearSync-init first."

Read the file to get user information.

### Step 2: Fetch User's Projects

Call `mcp__linear-server__list_projects(member="me", includeArchived=false, state="started,planned,paused", orderBy="updatedAt", limit=250)`

This returns all non-completed projects where the user is a member.

### Step 3: Process Each Project

For each project in the response:

1. Extract fields:
   - id
   - name
   - state (planned, started, paused, completed, canceled)
   - targetDate
   - lead (name)
   - teams (array)
   - progress (percentage)
   - url

2. Optionally call `mcp__linear-server__get_project(query="{project_id}")` if more details needed

### Step 4: Write to userProjects.md

Write to `~/.config/ai-context/mcps/userProjects.md`:

```markdown
# User Projects

Last synced: {current_timestamp}

## Active Projects

{For each project with state = 'started' or 'planned'}

### {ProjectName}

- **Project ID**: `{id}`
- **State**: {state}
- **Target Date**: {targetDate or 'Not set'}
- **Lead**: {lead_name or 'Unassigned'}
- **Team**: {team_name}
- **Progress**: {progress}%
- **Local Path**: `~/.config/ai-context/mcps/projects/{id}/`
- **Linear URL**: {url}

---

## Completed Projects

{For each project with state = 'completed'}

### {ProjectName}

- **Project ID**: `{id}`
- **State**: Completed
- **Target Date**: {targetDate}
- **Lead**: {lead_name}
- **Linear URL**: {url}

---

## Paused/Canceled Projects

{For each project with state = 'paused' or 'canceled'}

### {ProjectName}

- **Project ID**: `{id}`
- **State**: {state}
- **Linear URL**: {url}

---
```

### Step 5: Update linear.claude.md Timestamp

Update the "Last sync date" in `~/.config/ai-context/mcps/linear.claude.md` to current timestamp.

### Step 6: Display Summary

```
User Projects synced successfully!

Found {count} projects:
- Active: {active_count}
- Completed: {completed_count}
- Paused/Canceled: {paused_count}

File: ~/.config/ai-context/mcps/userProjects.md

Next steps:
- Run /linearSync-setActiveProject to select projects to work on
- Run /linearSync-AP-details to sync active project details
```

## Error Handling

- If linear.claude.md doesn't exist: "Error: Run /linearSync-init first"
- If Linear API fails: "Error: Cannot fetch projects from Linear. Check MCP connection."
- If no projects found: Display "No projects found. You may not be a member of any projects."

## Expected Output

User will see a summary of synced projects grouped by state (Active, Completed, Paused/Canceled).
