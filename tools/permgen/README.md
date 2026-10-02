# permgen

Generates the `permissions` block of `dots/.claude/settings.json` from a single
tool-agnostic source of truth (`permissions.yaml`).

## Why

Maintaining `dots/.claude/settings.json`'s `permissions` block by hand means
juggling the `Bash(...)`/`Read(...)` wrapper syntax and `:*` suffix rules
directly in JSON. `permgen` keeps a single tool-agnostic source of truth
(`permissions.yaml`) and derives the wrapped Claude permission strings from it.

## Usage

```sh
make perms/generate   # regenerate the permissions block in settings.json
make perms/check      # exit non-zero if settings.json is out of date (pre-commit/CI)
```

Or directly:

```sh
go run . [-claude .claude/settings.json] [-config permissions.yaml] [-check]
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

Within each section, the permissions are emitted sorted alphabetically.

## Source format (`permissions.yaml`)

Grouped by tool, bare values only — no `Bash(...)`/`Read(...)` wrapper, no `:*`:

```yaml
allow:
  bash:
    - git status        # -> Bash(git status:*)
    - cat               # -> Bash(cat:*)
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
bare tool permissions like `WebSearch` that take no argument).

## Adding Codex later

The pipeline is `parse YAML -> Config -> renderClaude`. Codex is not in this repo
yet; when it is, add a `renderCodex` that consumes the same neutral `Config` and
writes Codex's `~/.codex/config.toml`. Note:

- `permissions.yaml` stays tool-agnostic — do not add Claude-specific entries
  to it.
- Codex's permission model differs (approval policy + trusted commands), so
  `renderCodex` maps the neutral allow/deny/ask lists rather than reusing the
  Claude output.
