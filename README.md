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

## Nix (nix-darwin)

Macs are managed by a flake: nix-darwin (system settings, fonts, SSH, launchd),
home-manager (dotfiles and CLI tools) and nix-homebrew (Homebrew itself, casks,
and the few formulae missing from nixpkgs). Machines without Nix use
`make install` (GNU Stow).

```
flake.nix              list of hosts
hosts/<name>.nix       hostname, feature toggles (kit.*), host-only apps
modules/               shared by every host
  packages.nix         apps and tools: CLI (nixpkgs), fonts, brews, casks
  macos.nix            macOS defaults, applied to every user
  system.nix           Nix, users, Touch ID, Homebrew setup
  home.nix             links everything in dots/ into $HOME
  ssh.nix              optional features, off unless a host enables them
  always-on.nix
  agent.nix
docs/
  nix.md               install Nix, bootstrap a Mac, rollback
  post-install.md      steps to do by hand after the first apply
```

Host-specific things go in `hosts/<name>.nix`; everything else goes in the
matching file in `modules/`. Dotfiles go in `dots/`. A new host: add
`hosts/<name>.nix` and its name in `flake.nix`.

Every git-tracked file in `dots/` is symlinked into `$HOME`, pointing at this
checkout, so edits apply immediately. A new file needs a `just apply`, except
inside the directories listed in `wholeDirs` in `modules/home.nix`, which are
linked as a whole.

Flakes only see files tracked by git: `git add` new files before building.

Setup: [docs/nix.md](docs/nix.md). Then [docs/post-install.md](docs/post-install.md).
