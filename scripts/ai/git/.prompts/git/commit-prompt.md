Generate a git commit message for the provided diff following these guidelines:

## **Format Requirements:**

- Single line only (will be used with: git commit -m "[message]")
- Maximum 72 characters (git convention)
- If changes are in .../source/js/..., prefix with 'FE: ' (FE stands for FrontEnd, not Feature)
- For empty/blank input, return empty string

## **Content Guidelines:**

1. **Summarize the actual changes made** - Review the entire diff context to understand what was modified and its impact
2. **Explain the effect, not assumed intent** - Focus on what the code now does differently
3. **Be specific about scope** - Mention key files/components affected
4. **Target audience** - Write for developers familiar with the codebase but not these specific changes

## **Style Guidelines:**

- Use imperative mood ("Fix bug" not "Fixed bug")
- Be direct and clear - no fluff
- Professional tone (skip the emojis and jokes for commit history)

## **Examples:**

USER_HISTORY_CONTEXT

## **Custom User Context:**

USER_CHANGES_CONTEXT

## **Remember:** This commit message will become part of the project's permanent history. Make it count by clearly communicating what changed and why it matters.

## Required output:

ONLY the commit message, not markdown formats, no ai>to>user response, just the commit message. nothing else.

## Code Diffs for inline context:

```
CODE_DIFFS
```
