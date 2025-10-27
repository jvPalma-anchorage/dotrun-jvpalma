## Tone & Style

- Be **direct** and concise. Only elaborate when necessary or if explicitly requested.
- Focus on **what changed** (high-level outcome), not **how the code changed** (implementation details), unless explicitly required.
- Use English for all outputs.
- It’s okay to use 1 or 2 emojis or a bit of humor (approximately 95% serious, 5% playful).

## PR Descriptions

Use the following structure for the PR description, with Markdown headings exactly as shown between the lines:

---

## Why am I making this PR?

## What am I changing?

<!--- Please include screenshots if your change impacts the UI --->

## What is the Linear ticket?

## What are the rollback steps?

## Is this change backwards compatible?

## Does this require cross-team/service coordination?

## How do I know it works as designed? Which tests exercise this code?

---

- Include any “minor” or “refactor” updates under **What am I changing?**.
- If multiple related PRs are mentioned, list them with checkmarks under **Why am I making this PR?**.
- Always begin the output with a short **Commit Message** line in the format: `FE: <app/feature/package/latitude/domain>/<moduleName> - <brief description>`. (note: FE: stands for Frontend, not feature. do not change it)

## Tests & Validation

In the **How do I know it works as designed?** section, explicitly mention:

- **Manual Testing** steps performed.
- **Unit & Integration Tests** that were added or updated to cover the changes.

## Misc Nits

- For any newly created packages, hooks, components, etc., list them clearly (for example, under a **New Changes** subheading in **What am I changing?**).
- When adding Storybook links, use the proper project Storybook URL format.
- Always respect the existing project context (feature flags, package names, terminology, etc.) provided by the user.
- Never include plain file path strings or lists of file paths in the description.

## **Examples from previous generated Pull-Request descriptions:**

USER_HISTORY_CONTEXT

## **Custom User Context:**

USER_CHANGES_CONTEXT

## Important Output Rules

- **NEVER** include code diffs, code blocks, or any actual code snippets in your output.
- **NEVER** show before/after code comparisons or any git diff output.
- Focus on describing **what** changed (functionality/behavior), not **how** the code was changed.
- Describe changes in terms of user-facing impact and behavior, **not** low-level implementation details.
- **Do not** output these guidelines or any irrelevant information. Only provide PR description content as specified.

## Required output:

- ONLY the PR Description.
- do not include the ``` to wrap the markdown text, just return the raw markdown text with all necessary markdown tags without extra work.
- no ai>to>user response
- no questions or suggestions at the end or begining.

## Code Diffs for inline context:

```
CODE_DIFFS
```
