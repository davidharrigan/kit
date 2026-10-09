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
  macos.nix            macOS defaults
  system.nix           Nix, users, Touch ID, Homebrew setup
  home.nix             links everything in dots/ into $HOME
  ssh.nix              optional features, off unless a host enables them
  always-on.nix
  agent.nix
MANUAL.md              steps that can't be declared
```

Host-specific things go in `hosts/<name>.nix`; everything else goes in the
matching file in `modules/`. Dotfiles go in `dots/`. A new host: add
`hosts/<name>.nix` and its name in `flake.nix`.

Every git-tracked file in `dots/` is symlinked into `$HOME`, pointing at this
checkout, so edits apply immediately. A new file needs a `just apply`, except
inside the directories listed in `wholeDirs` in `modules/home.nix`, which are
linked as a whole.

Flakes only see files tracked by git: `git add` new files before building.

### Install Nix

Install Nix with the official community installer (uninstall with
`/nix/nix-installer uninstall`). If the Mac has an older Nix install, remove
it first.

```sh
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

### Bootstrap: existing Mac (stow and Homebrew already set up)

1. Build. Nothing is applied yet; fix errors before continuing.

   ```sh
   just build
   ```

2. Remove the stow links; home-manager won't replace symlinks it didn't create.
   Run without `-delete` first to see the list.

   ```sh
   find ~ -maxdepth 4 \( -path ~/Library -o -path ~/src -o -path ~/.Trash \) -prune \
     -o -type l -lname '*src/kit/dots*' -print -delete
   # git-ignored, so not linked by Nix; keep it as a plain local file
   cp dots/.claude/settings.local.json ~/.claude/
   ```

3. Apps installed by hand that are also in a cask list make `brew bundle`
   fail; adopt them first: `brew install --cask --adopt <cask>...`.

4. First apply:

   ```sh
   just apply
   ```

   - "Unexpected files in /etc": rename each listed file to
     `<file>.before-nix-darwin` and rerun.
   - "An existing /opt/homebrew/Library/Taps is in the way": move the old taps
     aside (`mv /opt/homebrew/Library/Taps /opt/homebrew/Library/Taps.before-nix`)
     and rerun. Only the taps pinned in the flake remain.
   - nix-homebrew takes over `/opt/homebrew`, keeping installed formulae and
     casks. home-manager renames regular files in its way to `<file>.before-hm`.

5. In a new shell, uninstall Homebrew formulae that now come from Nix
   (compare `brew leaves` with `modules/packages.nix`), then `brew autoremove`.
   While both exist, the Homebrew copy wins on PATH.

### Bootstrap: fresh Mac

Name the Mac after its `hosts/<name>.nix` file (System Settings → General →
Sharing), then:

```sh
xcode-select --install
# install Nix (above)
git clone https://github.com/davidharrigan/kit.git ~/src/kit && cd ~/src/kit
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
nix shell nixpkgs#just          # just isn't installed yet
just build
just apply
```

On a host with `kit.agent.enable`, install Oh My Zsh for the agent user after
the first apply. The apply already created `~agent/.oh-my-zsh/custom/themes`,
which makes the installer refuse to run, so remove it first and apply again to
restore the theme link:

```sh
sudo -u agent -H sh -c 'rm -rf ~/.oh-my-zsh && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc'
just apply
```

Then follow [MANUAL.md](MANUAL.md).

### Rollback

```sh
just generations                              # list system generations
just rollback                                 # previous generation
sudo darwin-rebuild --switch-generation N     # a specific one
```

If `darwin-rebuild` itself is broken, activate an older generation directly:
`sudo /nix/var/nix/profiles/system-<N>-link/activate`.

Full removal: `sudo nix run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-uninstaller` (restores the
`*.before-nix-darwin` files). To stop managing Homebrew, remove nix-homebrew
from `modules/system.nix`; the Homebrew installation then needs a
reinstall.

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
