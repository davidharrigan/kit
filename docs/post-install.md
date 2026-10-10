# Post-install steps

Things nix-darwin can't declare. Redo them after a fresh install.

## Both hosts

### Privacy & Security grants (TCC)

System Settings → Privacy & Security:

- **Accessibility**: Rectangle, Bartender.
- **Full Disk Access**: Ghostty, if a shell needs protected folders.
- **Screen Recording**: screenshot and screen-recording tools.

Grants to Nix-installed binaries point at a `/nix/store/...` path, which
changes when the package is rebuilt or updated. Re-grant if a tool loses
access after `just apply`.

### App Store

Only needed if `homebrew.masApps` is added later: sign in to the App Store
before applying.

## power (server)

### Touch ID

`sudo` with Touch ID needs a Magic Keyboard with Touch ID.

### Remote Login

nix-darwin starts sshd through launchctl. Check System Settings → General →
Sharing → Remote Login shows it as on.

### FileVault

`just bootstrap` enables it (`sudo fdesetup enable`); save the recovery key it
prints.

After a reboot or power loss the Mac waits at the unlock screen. On macOS 26+
it can be unlocked over SSH (`man apple_ssh_and_filevault`):

1. `ssh david@power` and enter david's password.
2. The connection drops briefly while the data volume mounts.
3. Reconnect normally with your key.

Before unlock, SSH accepts only a password: keys and
`/etc/ssh/sshd_config.d` live on the locked data volume. **Test this once after
setup.** UNVERIFIED: whether `PasswordAuthentication no` from this config
affects the pre-unlock prompt.

- Prefer Ethernet: pre-unlock Wi-Fi only works from macOS 26.5.
- Planned restarts: `sudo fdesetup authrestart` skips the unlock screen once.
- Tradeoff: after a power loss the server stays locked until unlocked by hand,
  and the agent doesn't run until it's unlocked and agent is logged in.

### Agent user

nix-darwin creates `agent` as a standard user (no admin, no sudo)
without a password or SecureToken, so it can't unlock FileVault. Its jobs
(the Herdr and Hermes launchd agents in `modules/agent.nix`) run inside its GUI
session, which desktop apps (e.g. Tauri) and a real browser need.

- `just bootstrap` enables Screen Sharing, installs Oh My Zsh and runs
  `just credentials` (below). `just bootstrap -i` also sets its password.
- After each reboot: unlock FileVault over SSH as david, then log agent in via
  Screen Sharing. If david is on the console, choose to log in as agent in a
  separate virtual session. Auto-login isn't possible with FileVault on.
- Act as it from a shell: `sudo -u agent -i`.
- Its SSH key (`~/.ssh/id_ed25519`) is generated on first apply.
- `just credentials` (run as david, also by `just bootstrap`) signs gh in (david as davidharrigan,
  agent as takohoncho; approve agent's device code in a browser signed in as
  takohoncho), uploads both SSH keys to GitHub, and creates the `agent` vault
  plus a read-only service account for it. Its token is saved in david's
  Private vault (override with `PRIVATE_VAULT=Personal`) and written to agent's
  `~/.config/op/service-account-token`, which `.zshrc` exports as
  `OP_SERVICE_ACCOUNT_TOKEN`. Secrets added to the `agent` vault are then
  readable by agent with `op read op://agent/<item>/<field>`.
- Login keychain unlocks with its GUI login; `sudo -u agent` shells don't get it.
- Git identity comes from the shared git config (david's). Override it for
  agent if needed.

### Hermes Agent

Hermes runs as agent: a gateway (cron, kanban dispatch) and a backend for
Hermes Desktop on `127.0.0.1:9119`. Profiles: `default` (chat),
`orchestrator`, `coder` and `reviewer` (kanban). Config is in
`modules/agent.nix`; settings shared by all profiles are pinned in
`/etc/hermes/config.yaml`. Hermes refuses `hermes config set`, `hermes model`
and `hermes update` here; change `modules/agent.nix` instead.

One-time, as agent with its GUI session logged in:

1. `claude auth status`: the Claude CLI must be logged in (Opus needs 2.1.280+).
2. `hermes auth add openai-codex`: approve the device code in a browser.
3. `hermes model`: check the Codex slugs in `modules/agent.nix` (`codexTop`,
   `codexSmall`) are listed; fix them and apply if not.
4. `hermes doctor`.

Repos the agent works on are listed in `repos.yaml`. `just sync-repos` (run as
david) clones each to its workdir under `/Users/agent/src` (the
language-server trust root), creates its kanban board with that default
workdir, and binds a project to the board so each card gets a worktree at
`<workdir>/.worktrees/<card>`. Safe to re-run after adding a repo.

Cron jobs are runtime state; create them as agent. Script-only jobs
(`--no-agent`) use no model. Useful ones:

- An issue poller: `gh issue list --label ready`, then for each issue
  `hermes kanban create … --assignee coder --workspace worktree
  --completion-contract OWNER/REPO --idempotency-key gh-<repo>-<N>`.
- A nightly backup: `hermes backup -o ~/backups/hermes.zip -k 7`.

From the laptop (chainsaw has the `hermes-desktop` cask):

1. `just hermes-tunnel` (forwards `127.0.0.1:9119` to power; Ctrl-C to stop)
2. Hermes Desktop → Settings → Gateways → Add → Remote gateway:
   `http://127.0.0.1:9119`, with the token from agent's
   `~/.hermes/backend-session-token`.
3. Keep the app at least at the backend's version.

Upgrades: bump the tag in `flake.nix`, `nix flake update hermes-agent`, run
`hermes backup --quick` as agent, apply, then `hermes doctor`. The first build
of each version is long (no binary cache). An apply that changes Hermes config
restarts both launchd agents, which interrupts any turn in flight.

Worktrees under `<repo>/.worktrees/` are kept after cards finish; prune them
now and then.
