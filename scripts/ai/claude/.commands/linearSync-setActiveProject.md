---
description: Interactively select active projects to sync and work on
tags: [linear, sync, projects, interactive]
---

# linearSync-setActiveProject: Set Active Projects

Interactively select which projects to set as "active" for detailed syncing and tracking.

## Prerequisites

- Linear sync system initialized (`/linearSync-init`)
- User projects synced (`/linearSync-userProjects`)
- `~/.config/ai-context/mcps/userProjects.md` exists

## Available Tools

- File system: Read, Write, Edit

## Thinking mode

- ultrathink

## Execution Steps

### Step 1: Read Current Active Projects

Read `~/.config/ai-context/mcps/linear.claude.md` and extract the "## User Active Projects" section.

Parse the current list of active projects (if any).

### Step 2: Read Available Projects

Read `~/.config/ai-context/mcps/userProjects.md` to get the list of all user projects.

Extract:

- Project Name
- Project ID
- State
- Target Date

Filter to show only projects with state = 'started' or 'planned' (exclude completed/canceled).

### Step 3: Present Current State and Options

Display to user:

```
Current Active Projects:
{If active projects exist}
1. {ProjectName1} (ID: {id1})
2. {ProjectName2} (ID: {id2})
{else}
(None set)

Available Projects:
{numbered list of all active/planned projects}

Example:
Available Projects:
1. E-commerce Redesign (ID: proj_abc123) - Started - Target: 2025-11-15
2. Mobile App V2 (ID: proj_def456) - Planned - Target: 2025-12-01
3. API Performance Improvements (ID: proj_ghi789) - Started - Target: 2025-10-30

---

Instructions:
- Enter project numbers to set as active (comma-separated): Example: 1,3
- Enter 'all' to set all projects as active
- Enter 'none' to clear active projects
- Enter 'cancel' to exit without changes

Your selection:
```

### Step 4: Wait for User Input

Pause and wait for user to type their selection.

Parse the input:

- If "cancel" → exit without changes
- If "none" → clear active projects list
- If "all" → set all available projects as active
- If numbers (e.g., "1,3") → set those specific projects as active

Validate:

- Numbers are within range
- Projects exist

### Step 5: Update linear.claude.md

Update the "## User Active Projects" section in `~/.config/ai-context/mcps/linear.claude.md`:

```markdown
## User Active Projects

Last updated: {current_timestamp}

1. {ProjectName1}
   - **Project ID**: `{id1}`
   - **Path**: `~/.config/ai-context/mcps/projects/{id1}/`

2. {ProjectName2}
   - **Project ID**: `{id2}`
   - **Path**: `~/.config/ai-context/mcps/projects/{id2}/`
```

If "none" was selected:

```markdown
## User Active Projects

Last updated: {current_timestamp}

_(No active projects set)_
```

### Step 6: Display Confirmation

```
Active projects updated successfully!

Now active:
1. {ProjectName1} (proj_abc123)
2. {ProjectName2} (proj_ghi789)

Next steps:
1. Run /linearSync-AP-details to sync project details
2. Run /linearSync-AP-myIssues to sync your issues
3. Run /linearSync-AP-disciplineIssues to sync discipline issues
4. Run /linearSync-AP-otherIssues to sync other team issues
5. Run /linear-NextTask to pick your next task
```

## Example User Flow

**User Input**: `1,3`

**System Response**:

```
Active projects updated successfully!

Now active:
1. E-commerce Redesign (proj_abc123)
2. API Performance Improvements (proj_ghi789)

You can now sync these projects in detail.
```

## Error Handling

- If userProjects.md doesn't exist: "Error: Run /linearSync-userProjects first"
- If invalid selection: "Error: Invalid selection. Please enter valid project numbers."
- If no projects available: "No projects available. Run /linearSync-userProjects to discover projects."

## Multi-Project Support

This command supports multiple active projects. Users can work on several projects simultaneously, and all sync commands will process all active projects.

## Expected Output

User will see confirmation of their active project selection with next steps for syncing detailed project data.
