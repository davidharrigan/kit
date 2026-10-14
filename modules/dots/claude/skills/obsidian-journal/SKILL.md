---
name: obsidian-journal
description: Quick-capture a journal entry into the ~/me/journal Obsidian vault using the obsidian CLI. Use when the user says "add a journal entry", "jot this down in my journal/vault", "write a note into Obsidian", or similar quick-capture requests aimed at their personal vault. Not for editing existing notes or creating category/reference notes.
license: MIT
allowed-tools: Bash
---

# Obsidian Journal Quick Capture

Create a journal entry in the `~/me/journal` vault via the `obsidian` CLI, following that vault's documented journal convention (`VAULT.md` section 8). This is the vault's designated low-friction way to capture a note — no category or folder decision needed.

## Prerequisites

- Obsidian must be running with the vault open (the CLI talks to a live instance).
- Always pass `vault=journal` explicitly — the user has multiple vaults open, and the CLI otherwise targets whichever was most recently focused.

## Steps

1. **Get local date/time**:
   ```bash
   date +%Y-%m-%d      # created date, e.g. 2026-08-16
   date +%H%M           # for filename, e.g. 2230
   date +"%Y-%m-%d %H:%M"  # for created property, e.g. 2026-08-16 22:30
   ```
2. **Build the filename**: `YYYY-MM-DD HHmm Description.md` — a short, specific description in title case, no colons or slashes.
3. **Build the frontmatter + body**. Minimum required properties are `created` and `tags: [journal]`. Add `related` only when the entry belongs to an existing durable note (link it directly); otherwise leave `related: []`. Add `categories` only if it clearly improves retrieval — most journal entries have none.

   ```yaml
   ---
   created: 2026-08-16 22:30
   tags:
     - journal
   related: []
   ---

   Entry body in plain prose. Use [[wikilinks]] for the first meaningful mention of a person, project, or place.
   ```
4. **Create the file** with the CLI, escaping newlines as `\n` in the `content` value:
   ```bash
   obsidian vault=journal create path="Notes/2026-08-16 2230 Description.md" content="---\ncreated: 2026-08-16 22:30\ntags:\n  - journal\nrelated: []\n---\n\nEntry body here." silent
   ```
   - Journal entries live in `Notes/` (not a `Journal/` folder), per `VAULT.md`.
   - Use `silent` to avoid opening Obsidian's window for a quick capture. Drop it if the user wants to see the note.
5. **Confirm** by reading it back: `obsidian vault=journal read path="Notes/<filename>.md"`.

## Notes

- Write all dates as `YYYY-MM-DD`; the `created` property uses `YYYY-MM-DD HH:mm` (24-hour, local time).
- Quote any CLI value containing spaces.
- If the entry clearly belongs to an ongoing project or person note the user has mentioned, add it to `related` as `"[[Note Name]]"` — this is how the journal links back into durable notes without leaving the journal itself.
- This skill only creates new journal entries. For editing existing notes, general note creation across categories, or vault upkeep, defer to the vault's own `obsidian-cli`, `obsidian-markdown`, or `vault-groom` skills (in `~/me/journal/skills/`).
