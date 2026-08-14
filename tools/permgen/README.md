# permgen

Generates the `permissions` block of `dots/.claude/settings.json` from a single
tool-agnostic source of truth (`permissions.yaml`).

## Why

The permission list needs an `rtk`-prefixed twin for every command the
`rtk hook claude` PreToolUse hook rewrites at runtime — otherwise the rewritten
command isn't pre-approved and Claude prompts. Maintaining those twins by hand
is error-prone and was already wrong in places: the hook rewrites
`cat`/`head`/`tail` to **`rtk read`**, not `rtk cat`, so the old `rtk cat` entry
never matched anything.

`permgen` keeps `permissions.yaml` free of `rtk` duplicates and derives the
correct twins by asking rtk itself (`rtk hook check "<cmd>"`) how each command is
actually rewritten. That stays correct across rtk versions and coverage changes.

## Usage

```sh
make perms/generate   # regenerate the permissions block in settings.json
make perms/check      # exit non-zero if settings.json is out of date (pre-commit/CI)
```

Or directly:

```sh
go run . -config permissions.yaml -claude ../../dots/.claude/settings.json [-check] [-rtk rtk]
```

Only the top-level `permissions` key is rewritten; every other key in
`settings.json` (and its order) is preserved byte-for-byte.

## Source format (`permissions.yaml`)

Grouped by tool, bare values only — no `Bash(...)`/`Read(...)` wrapper, no `:*`,
no `rtk ` duplicates:

```yaml
allow:
  bash:
    - git status        # -> Bash(git status:*)  + Bash(rtk git status:*)
    - cat               # -> Bash(cat:*)         + Bash(rtk read:*)
    - rtk json          # rtk-native, kept verbatim -> Bash(rtk json:*)
  read:
    - ~/.aws/**         # -> Read(~/.aws/**)
```

Wrapping rule for `bash` values: a value containing `*` is used verbatim inside
`Bash(...)` (literal glob, e.g. `rm -rf /*`); otherwise `:*` is appended.
`read` values become `Read(<value>)` verbatim. rtk-prefixing applies to `bash`
only.

- allow/ask: precise — probes rtk for the real rewrite (maps cat/head/tail →
  `rtk read`, adds twins only for commands rtk actually covers).
- deny: broad — every command-leading entry also gets a naive `rtk ` twin so
  rtk-native invocations are blocked too.

## Adding Codex later

The pipeline is `parse YAML -> Config -> renderClaude`. Codex is not in this repo
yet; when it is, add a `renderCodex` that consumes the same neutral `Config` and
writes Codex's `~/.codex/config.toml`. Note:

- `permissions.yaml` stays tool-agnostic — do not add Claude- or rtk-specific
  entries to it.
- rtk-prefixing is a **Claude-render concern** (Codex has no equivalent
  PreToolUse hook), so it lives in `renderClaude`, not the shared model.
- Codex's permission model differs (approval policy + trusted commands), so
  `renderCodex` maps the neutral allow/deny/ask lists rather than reusing the
  Claude output.
