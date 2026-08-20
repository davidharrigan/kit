# permgen

Generates the `permissions` block of `dots/.claude/settings.json` from a single
tool-agnostic source of truth (`permissions.yaml`).

## Why

Maintaining `dots/.claude/settings.json`'s `permissions` block by hand means
juggling the `Bash(...)`/`Read(...)` wrapper syntax and `:*` suffix rules
directly in JSON. `permgen` keeps a single tool-agnostic source of truth
(`permissions.yaml`) and derives the wrapped Claude permission strings from it.

The permission list also needs an `rtk`-prefixed twin for every command the
`rtk hook claude` PreToolUse hook rewrites at runtime — otherwise the rewritten
command isn't pre-approved and Claude prompts. Maintaining those twins by hand
is error-prone and was already wrong in places: the hook rewrites
`cat`/`head`/`tail` to **`rtk read`**, not `rtk cat`, so a hand-written `rtk cat`
entry never matches anything.

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
go run . [-claude .claude/settings.json] [-config permissions.yaml] [-check] [-rtk rtk]
```

`-claude` defaults to `./.claude/settings.json`; its parent `.claude` directory
must exist or permgen errors.

By default the source is the merge of two `permissions.yaml` files, in order:

1. `~/.agents/permissions.yaml` (global)
2. `./.agents/permissions.yaml` (project, relative to cwd)

Missing files are skipped silently; it is an error only if neither exists. Their
`allow`/`deny`/`ask` lists are concatenated (project entries appended after
global). Pass `-config <file>` to override this and use a single source file
instead.

Only the top-level `permissions` key is rewritten; every other key in
`settings.json` (and its order) is preserved byte-for-byte.

Within each section, the natural permissions are emitted first, sorted
alphabetically, followed by the auto-generated `rtk`-prefixed twins, also sorted
alphabetically.

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
  webfetch:
    - domain:github.com # -> WebFetch(domain:github.com)
  raw:
    - WebSearch          # -> WebSearch (passed through unwrapped)
```

Wrapping rule for `bash` values: a value containing `*` is used verbatim inside
`Bash(...)` (literal glob, e.g. `rm -rf /*`); otherwise `:*` is appended.
`read` values become `Read(<value>)` verbatim. `webfetch` values become
`WebFetch(<value>)` verbatim. `raw` values are passed through unwrapped (for
bare tool permissions like `WebSearch` that take no argument). rtk-prefixing
applies to `bash` only.

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
