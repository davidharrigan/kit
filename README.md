# kit

This is my dev kit.  It install config I need to stay productive on any machine.

## What's in it?
```bash
├── Makefile                 # for easy installation
├── backup                   # any existinng config will be backed up here on install
├── dots
│   ├── aliases              # aliases, everything here will be sourced
│   │   └── common.alias
│   ├── config
│   │   └── nvim
│   │       └── init.vim
│   ├── env                  # environment variables, everything here will be sourced
│   │   └── common.env
│   └── zshrc
└── terminal                 # terminal utilities
```

## Codex

`dots/.codex/` contains the non-sensitive parts of the current Codex setup:
model and UI preferences, plugin toggles, the public Datadog MCP endpoint,
keybindings, and the Herdr session hook. The hook uses `CODEX_HOME` (falling back
to `~/.codex`) instead of a machine-specific path; its helper is managed by Herdr.

These files use the existing `make install` / GNU Stow workflow, targeting
`~/.codex`, Codex's [user configuration directory](https://learn.chatgpt.com/docs/config-file/config-basic).
Installation backs up conflicting files under `backup/` and replaces them with
symlinks; it does not merge local settings. This snapshot has not been installed.

Credentials and HTTP headers, project trust entries, command approval rules,
hook trust hashes, app-managed computer-use and marketplace paths, versioned
skill paths, caches, sessions, history, and databases are intentionally omitted.
Set up integrations and authentication locally after restoring; plugin toggles
do not install plugins. The empty local `AGENTS.md` is also omitted.

The root `.gitignore` allows only the reviewed Codex files. Review changes to
tracked configuration before committing: Codex can write local settings back
into those files, and Git ignore rules do not filter their contents.
