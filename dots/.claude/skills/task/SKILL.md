---
name: task
description: "Launch an orchestrator session in a new cmux workspace for a unit of work — a GitHub issue, a Jira ticket, a URL, or a task described in plain words. The orchestrator decomposes the work into multiple small PRs, runs a fresh worktree-isolated agent per slice, reviews each slice before opening its PR, then watches the open PRs for the user's feedback and merges. Use when the user types /task <whatever>."
---

# /task

Launch a dedicated orchestrator session for a unit of work, in its own cmux
workspace — named for the task, grouped under its repo, and tinted a per-repo
purple shade so orchestrators from the same repo cluster together in the
sidebar. The new session inherits the caller's permission mode, so it starts
working with the same autonomy the user has already granted.

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

## 2. Launch

Write the resolved brief to a file with the **Write tool** — never a shell
heredoc. Briefs contain quotes, backticks, and newlines that will not survive a
one-liner, and the Write tool needs no escaping and no approval:

```
Write  <scratchpad>/task-brief.md   ← the resolved brief text, verbatim
```

Then run this **once** from inside the target repo. It is one command, and the
script renders the orchestrator prompt (`orchestrator.md` + your brief + the
closing reference) internally, so there is nothing to escape and nothing to
approve beyond this call:

```bash
~/.claude/skills/task/scripts/launch.sh "<task-id>" "<one-line summary>" "<closing-ref>" "<brief-file>"
```

`<closing-ref>` is `Closes #N` for a same-repo GitHub issue, or `none`.

The script does everything deterministic about the launch, and must not be
reimplemented inline:

- **Renders the prompt** — substitutes `{{TASK_ID}}` in `orchestrator.md` and
  appends the closing reference and your brief under `## The work`.
- **Inherits the caller's permission mode** — it reads the live `permissionMode`
  from this session's transcript and forwards it to the child `claude` via
  `--permission-mode`, so the orchestrator starts with the same autonomy you
  currently have. (Normal/`default` mode passes no flag — the child's natural
  default.)
- **Groups the workspace under its repo** — one sidebar group per repo, created
  from the first orchestrator for that repo (no phantom anchor workspace).
- **Tints group, row, and status pill** a deterministic purple shade derived
  from the repo name, and exports it as `TASK_SHADE` so the orchestrator's own
  status updates keep the same shade.
- Creates the workspace **unfocused**, in the **main checkout** (not a worktree),
  so the orchestrator can see every slice branch.

It prints two lines — `WORKSPACE workspace:<N>` and `MODE <mode>`. Parse both;
the hand-off reports them. On any `ERROR:` line, stop and show it to the user.

## 3. Hand off

Tell the user the workspace name and ref it landed in, which permission mode it
inherited, and that the orchestrator will post its slice plan before starting
work. Then stop. Do not do any of the work in the calling session.

## Rules

- One orchestrator workspace per task. Check `cmux workspace list` for a
  workspace already named for this task id; if one exists, say so and offer to
  message it with `SendMessage` rather than launching a second one.
- Never call `focus-pane`, `focus-panel`, or `select-workspace` from this skill.
- The calling session does not track the work. Once launched, the orchestrator
  owns it.
