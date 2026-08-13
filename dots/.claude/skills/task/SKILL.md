---
name: task
description: "Launch an orchestrator session in a new cmux workspace for a unit of work — a GitHub issue, a Jira ticket, a URL, or a task described in plain words. The orchestrator decomposes the work into multiple small PRs, runs a fresh worktree-isolated agent per slice, reviews each slice before opening its PR, then watches the open PRs for the user's feedback and merges. Use when the user types /task <whatever>."
---

# /task

Launch a dedicated orchestrator session for a unit of work, in its own cmux
workspace — named for the task, and colored so it reads as an orchestrator at a
glance in the sidebar.

```
/task 42                                  # GitHub issue in the current repo
/task https://github.com/o/r/issues/42     # GitHub issue by URL
/task PROJ-1234                            # Jira ticket
/task "split the export pipeline in two"   # plain description
```

This skill does **only** the launch and the task resolution. All work doctrine
lives in [orchestrator.md](orchestrator.md), which is rendered and handed to the
new session as its opening prompt.

## 1. Resolve the task source

The argument is free-form. Identify what it is and produce a **task brief** —
the text the orchestrator will work from.

| Argument looks like | Do this |
|---|---|
| `42`, `#42` | `gh issue view 42 --json number,title,body,url` |
| a GitHub issue/PR URL | `gh issue view <url> --json number,title,body,url` |
| `ABC-1234` (Jira key) | Try a Jira CLI if one is on PATH (`jira issue view ABC-1234`). If none, ask the user to paste the ticket description — do not invent it. |
| anything else | Treat the argument as the task brief verbatim. |

If a lookup fails or returns nothing, stop and ask. Never guess at what the work
is.

Then derive a **task id**: a short kebab slug used to name the PR watch-list file
and to prefix branches. Use `issue-42` / `proj-1234` when there is a ticket, or
three-or-four words from the description otherwise (`split-export-pipeline`).

Record whether a **closing reference** applies: only a GitHub issue in the target
repo gets `Closes #N` in a PR body. A Jira key or a plain description does not —
reference it in prose instead.

## 2. Render the prompt

Write the rendered prompt to a temp file rather than substituting inline. Task
briefs contain quotes, backticks, and newlines that will not survive a shell
one-liner:

```bash
PROMPT=$(mktemp /tmp/task-XXXXXX.md)
sed -e "s|{{TASK_ID}}|<task-id>|g" ~/.claude/skills/task/orchestrator.md > "$PROMPT"
```

Then append the resolved brief under the `## The work` heading at the end of the
file, with a `Closing reference:` line stating either `Closes #N` or `none`.
Appending sidesteps escaping entirely.

## 3. Launch the workspace

Create the workspace **unfocused** — the user may be looking elsewhere. Name it
for the task id, and start it in the **main checkout**, not a worktree: the
orchestrator spawns worktree-isolated agents and must be able to see all of
their branches.

```bash
cmux workspace create --name "<task-id>" \
  --cwd "$(git rev-parse --show-toplevel)" \
  --description "<one-line task summary>" \
  --focus false \
  --command 'claude "$(cat '"$PROMPT"')"'
```

`--command` sends its text plus Enter to the new workspace's terminal, so the
`$(cat ...)` runs in *that* shell. Keep the outer single quotes exactly as
written — they stop the calling shell from expanding the substitution first.
Nested quotes, backticks, and `$` in the brief survive this intact.

The command prints `OK workspace:<N>`. Capture that ref — the next step needs
it. (`--json` is accepted but not honored here; parse the `OK` line.)

## 4. Mark it as an orchestrator

Two indicators, both workspace-scoped. Set them immediately after creation:

```bash
cmux workspace-action --workspace workspace:<N> --action set-color --color Purple
cmux set-status orchestrator "<task-id>" --workspace workspace:<N> \
  --icon sparkle --color "#a855f7" --priority 80
```

Reserve **Purple** for orchestrator workspaces so the color means one thing. The
status pill rides in the sidebar row next to the name; the orchestrator updates
its value as work progresses (see orchestrator.md), and it is cleared on finish.

Set `CMUX_QUIET=1` for these calls if the deprecation notices are noisy.

## 5. Hand off

Tell the user the workspace name and ref it landed in, and that the orchestrator
will post its slice plan before starting work. Then stop. Do not do any of the
work in the calling session.

## Rules

- One orchestrator workspace per task. Check `cmux workspace list` for a
  workspace already named for this task id; if one exists, say so and offer to
  message it with `SendMessage` rather than launching a second one.
- Never call `focus-pane`, `focus-panel`, or `select-workspace` from this skill.
- The calling session does not track the work. Once launched, the orchestrator
  owns it.
