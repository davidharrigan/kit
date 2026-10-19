---
name: "source-command-hand-off"
description: "Create context handoff for session continuation"
---

# source-command-hand-off

Use this skill when the user asks to run the migrated source command `hand-off`.

## Command Template

# /handoff

Save state for continuation in new chat (use when context ~10-15% remaining).

## Execute

1. Summarize current project/phase
2. Note key files and decisions
3. Save to .Codex/handoffs/handoff-[date]-[time].md
4. Provide continuation prompt

## Handoff Format

```
# Context Handoff - [Date]

## Current Project / Plan
## Current Phase
## Work Completed This Session
## Key Files
## Decisions Made
## Next Steps
## Continuation Prompt
```

## Output

```
Handoff saved to: .Codex/handoffs/handoff-YYYY-MM-DD-HHMM.md

To continue, paste:
---
Resume from handoff: [path]
Context: [brief]
Next: [action]
---
```
