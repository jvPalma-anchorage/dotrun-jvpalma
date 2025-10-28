---
description: Sync team's Linear projects grouped by quarter to teamProjects.md
tags: [linear, sync, projects, team]
---

# linearSync-teamProjects: Sync Team Projects

Synchronize all team projects grouped by quarter to `~/.config/ai-context/mcps/teamProjects.md`.

## Prerequisites

- Linear sync system initialized (`/linearSync-init`)
- `~/.config/ai-context/mcps/linear.claude.md` exists with Team information

## Available Tools

- Linear MCP: `mcp__linear-server__list_teams`, `mcp__linear-server__list_cycles`, `mcp__linear-server__list_projects`
- File system: Read, Write

## Thinking mode

- ultrathink

## Execution Steps

### Step 1: Read User Team Information

Read `~/.config/ai-context/mcps/linear.claude.md` to get the user's Team name.

If Team is not set, prompt user: "Which team's projects would you like to sync?"

### Step 2: Get Team ID

Call `mcp__linear-server__list_teams()` to get all teams.

Find the team matching the user's Team name and extract the team ID.

### Step 3: Get Current Cycle Information

Call `mcp__linear-server__list_cycles(teamId="{team_id}", type="current")` to get the current cycle/sprint information.

Extract cycle dates to understand the current quarter context.

### Step 4: Fetch Team Projects

Call `mcp__linear-server__list_projects(team="{team_id}", includeArchived=false, state="started,planned,paused", orderBy="updatedAt", limit=250)`

This returns all non-completed projects for the specified team.

### Step 5: Group Projects by Quarter

For each project, parse the `targetDate` field and group by quarter:

Quarter calculation:

- Q1: January - March (01-03)
- Q2: April - June (04-06)
- Q3: July - September (07-09)
- Q4: October - December (10-12)

If targetDate is null, place in "Unscheduled" section.

Calculate:

- Current Quarter: Q4 2025 (since today is 2025-10-01)
- Next Quarter: Q1 2026
- Future Quarters: Q2 2026 and beyond

### Step 6: Write to teamProjects.md

Write to `~/.config/ai-context/mcps/teamProjects.md`:

```markdown
# Team Projects

Last synced: {current_timestamp}
Team: {team_name}
Team ID: {team_id}

## Current Quarter (Q4 2025)

{For each project with targetDate in Oct-Dec 2025}

- **{ProjectName}** ({state})
  - Target: {targetDate}
  - Lead: {lead_name}
  - Progress: {progress}%
  - Linear: {url}

---

## Next Quarter (Q1 2026)

{For each project with targetDate in Jan-Mar 2026}

- **{ProjectName}** ({state})
  - Target: {targetDate}
  - Lead: {lead_name}
  - Progress: {progress}%
  - Linear: {url}

---

## Future Quarters

### Q2 2026 (Apr-Jun)

{For each project with targetDate in Apr-Jun 2026}

- **{ProjectName}** ({state})
  - Target: {targetDate}
  - Lead: {lead_name}
  - Linear: {url}

### Q3 2026 (Jul-Sep)

{Projects...}

### Q4 2026 (Oct-Dec)

{Projects...}

---

## Unscheduled

{For each project with no targetDate}

- **{ProjectName}** ({state})
  - Lead: {lead_name}
  - Progress: {progress}%
  - Linear: {url}

---

## Planning Stage

{For each project with state = 'planned'}

- **{ProjectName}**
  - Target: {targetDate or 'TBD'}
  - Lead: {lead_name}
  - Linear: {url}
```

### Step 7: Update Sync Timestamp

Update the "Last sync date" in `~/.config/ai-context/mcps/linear.claude.md`.

### Step 8: Display Summary

```
Team Projects synced successfully!

Team: {team_name}
Found {count} projects:
- Current Quarter (Q4 2025): {current_quarter_count}
- Next Quarter (Q1 2026): {next_quarter_count}
- Future Quarters: {future_count}
- Unscheduled: {unscheduled_count}

File: ~/.config/ai-context/mcps/teamProjects.md

Next steps:
- Review team roadmap in teamProjects.md
- Run /linearSync-userProjects to see your specific projects
- Run /linearSync-setActiveProject to select projects to work on
```

## Error Handling

- If Team not found: "Error: Team '{team_name}' not found. Available teams: {list_teams}"
- If linear.claude.md doesn't exist: "Error: Run /linearSync-init first"
- If no projects found: "No projects found for team '{team_name}'"

## Expected Output

User will see a summary of team projects organized by quarter, with current quarter highlighted.
