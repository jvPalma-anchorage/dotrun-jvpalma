---
description: Sync active project details and status updates
tags: [linear, sync, projects, active-project]
---

# linearSync-AP-details: Sync Active Project Details

Synchronize detailed information for all active projects, including project description and status updates.

## Prerequisites

- Active projects set (`/linearSync-setActiveProject`)
- `~/.config/ai-context/mcps/linear.claude.md` has active projects defined

## Available Tools

- Linear MCP: `mcp__linear-server__get_project`
- File system: Read, Write, Bash

## Thinking mode

- ultrathink

## Execution Steps

### Step 1: Read Active Projects

Read `~/.config/ai-context/mcps/linear.claude.md` and extract the "## User Active Projects" section.

Parse the list of active project IDs.

If no active projects found, display: "Error: No active projects set. Run /linearSync-setActiveProject first."

### Step 2: For Each Active Project

Loop through each active project ID and perform the following:

#### 2a. Create Project Folder

```bash
mkdir -p ~/.config/ai-context/mcps/projects/{PROJECT_ID}
```

Create the project folder if it doesn't exist.

#### 2b. Fetch Project Details

Call `mcp__linear-server__get_project(query="{project_id}")` to get full project information.

Extract fields:

- id
- name
- description (markdown)
- state (planned, started, paused, completed, canceled)
- startDate
- targetDate
- completedAt
- progress (percentage 0-100)
- lead (user object with name)
- teams (array of team objects)
- url (Linear URL)
- scope (number - issue count estimate)
- slackNewIssue (boolean)
- slackIssueComments (boolean)
- slackIssueStatuses (boolean)

#### 2c. Check for Existing ProjectDetails.md

Check if `~/.config/ai-context/mcps/projects/{PROJECT_ID}/ProjectDetails.md` exists.

If it exists, read it and compare key fields:

- state
- progress
- targetDate
- lead

If any of these changed, note the changes for ProjectStatusUpdates.md.

#### 2d. Write ProjectDetails.md

Write to `~/.config/ai-context/mcps/projects/{PROJECT_ID}/ProjectDetails.md`:

```markdown
# {ProjectName}

**Project ID**: `{id}`
**State**: {state}
**Lead**: {lead_name}
**Team**: {team_names (comma-separated if multiple)}
**Start Date**: {startDate or 'Not set'}
**Target Date**: {targetDate or 'Not set'}
**Completed**: {completedAt or 'N/A'}
**Progress**: {progress}%
**Scope**: {scope} issues

## Description

{description (full markdown content)}

## Links

- **Linear**: {url}

## Sync Information

- **Last synced**: {current_timestamp}
- **File created**: {original_creation_timestamp (preserve if exists)}

---

_This file is auto-generated. Do not edit manually. Run /linearSync-AP-details to update._
```

#### 2e. Update ProjectStatusUpdates.md

If this is the first sync OR if there were changes detected:

**For first sync**, create `~/.config/ai-context/mcps/projects/{PROJECT_ID}/ProjectStatusUpdates.md`:

```markdown
# Project Status Updates: {ProjectName}

This file tracks changes to the project over time.

## Update: {current_date}

**Event**: Project tracking initialized
**State**: {state}
**Progress**: {progress}%
**Target Date**: {targetDate}

---
```

**For subsequent syncs with changes**, append to the file:

```markdown
## Update: {current_date}

**State**: {old_state} → {new_state}
**Progress**: {old_progress}% → {new_progress}%
**Target Date**: {old_targetDate} → {new_targetDate}
**Lead**: {old_lead} → {new_lead}

**Changes detected**:

- {list of specific changes}

---
```

If no changes detected, don't append anything new.

### Step 3: Display Summary

After processing all active projects:

```
Active project details synced successfully!

Synced {count} projects:

1. {ProjectName1}
   - State: {state}
   - Progress: {progress}%
   - Changes: {Yes/No}
   - Path: ~/.config/ai-context/mcps/projects/{id1}/

2. {ProjectName2}
   - State: {state}
   - Progress: {progress}%
   - Changes: {Yes/No}
   - Path: ~/.config/ai-context/mcps/projects/{id2}/

Files created/updated:
- ProjectDetails.md (x{count})
- ProjectStatusUpdates.md (x{changes_count} with updates)

Next steps:
- Run /linearSync-AP-myIssues to sync your assigned issues
- Run /linearSync-AP-disciplineIssues to sync discipline issues
- Run /linearSync-AP-otherIssues to sync other team issues
```

## Change Detection Logic

Detect changes by comparing:

1. **State** (planned → started, started → completed, etc.)
2. **Progress** (percentage change > 5%)
3. **Target Date** (date changed)
4. **Lead** (lead changed)

Only log meaningful changes to avoid cluttering the status updates file.

## Error Handling

- If active project not found in Linear: "Warning: Project {id} not found in Linear. It may have been deleted."
- If Linear API fails: "Error: Cannot fetch project details. Check Linear MCP connection."
- If folder creation fails: "Error: Cannot create project folder. Check permissions."

## Multiple Active Projects

This command processes ALL active projects in sequence. Progress is shown for each project.

## Expected Output

User will see a summary of synced projects with change detection results.
