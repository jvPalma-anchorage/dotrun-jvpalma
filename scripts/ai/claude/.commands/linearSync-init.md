---
description: Initialize Linear sync system - create folder structure and gather user info
tags: [linear, sync, initialization, setup]
---

# linearSync-init: Initialize Linear Sync System

You are initializing the Linear synchronization system for Claude Code. This is a one-time setup process.

## Available Tools

- Linear MCP server tools: `mcp__linear-server__*`
- File system tools: Read, Write, Bash, Glob

## Thinking mode

- ultrathink

## Execution Steps

### Step 1: Create Base Directory Structure

Create the following folder structure if it doesn't exist:

```
~/.config/ai-context/mcps/
├── projects/
├── linear.claude.md
├── userProjects.md
└── teamProjects.md
```

Use Bash to create directories:

```bash
mkdir -p ~/.config/ai-context/mcps/projects
```

### Step 2: Fetch User Information from Linear

Call `mcp__linear-server__get_user(query="me")` to retrieve the authenticated user's details.

Extract the following fields:

- id
- name
- email
- displayName
- admin (boolean)
- active (boolean)
- createdAt (date)

### Step 3: Gather Additional Information

Prompt the user to provide:

1. **Team**: Which Linear team do you primarily work with? (If user has multiple teams, ask them to specify)
2. **Discipline**: What is your primary discipline?
   - Frontend
   - Backend
   - Fullstack
   - DevOps
   - Design
   - QA
   - Product
   - Other (specify)

Present this as an interactive prompt and wait for user input.

### Step 4: Calculate Current Quarter

Based on today's date (2025-10-01), calculate the current quarter:

- Q1: January - March
- Q2: April - June
- Q3: July - September
- Q4: October - December

Current quarter: Q4 2025

### Step 5: Create linear.claude.md

Write `~/.config/ai-context/mcps/linear.claude.md` with the following structure:

```markdown
## User Information

- **User ID**: {id}
- **Name**: {name}
- **Email**: {email}
- **Display Name**: {displayName}
- **Admin**: {admin}
- **Active**: {active}
- **Created**: {createdAt}
- **Team**: {team}
- **Discipline**: {discipline}

## Scanned Linear Information

- **Current Quarter**: Q4 2025
- **Last sync date**: {current_timestamp}

## User Active Projects

_(Active projects will be set using /linearSync-setActiveProject)_
```

### Step 6: Initialize Empty Index Files

Create empty `~/.config/ai-context/mcps/userProjects.md`:

```markdown
# User Projects

Last synced: {timestamp}

_(Run /linearSync-userProjects to sync your projects)_
```

Create empty `~/.config/ai-context/mcps/teamProjects.md`:

```markdown
# Team Projects

Last synced: {timestamp}

_(Run /linearSync-teamProjects to sync team projects)_
```

### Step 7: Confirm Success

Display a success message:

```
Linear sync system initialized successfully!

Created:
- ~/.config/ai-context/mcps/
- ~/.config/ai-context/mcps/projects/
- ~/.config/ai-context/mcps/linear.claude.md
- ~/.config/ai-context/mcps/userProjects.md
- ~/.config/ai-context/mcps/teamProjects.md

User: {name} ({email})
Team: {team}
Discipline: {discipline}

Next steps:
1. Run /linearSync-userProjects to discover your projects
2. Run /linearSync-teamProjects to discover team projects
3. Run /linearSync-setActiveProject to select active projects
4. Run /linearSync-AP-details to sync project details
5. Run /linearSync-AP-myIssues to sync your issues
```

## Error Handling

- If Linear MCP server is unavailable, display: "Error: Linear MCP server not available. Please ensure it's configured in your MCP settings."
- If folder creation fails, display: "Error: Cannot create directory structure. Check permissions for ~/.config/ai-context/mcps/"
- If user data is incomplete, prompt for manual input

## Expected Output

User will see confirmation of successful initialization with their profile information and next steps.
