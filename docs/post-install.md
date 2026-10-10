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

Nix installs the `hermes` CLI for agent (pinned by the `hermes-agent` flake
input) and runs two launchd agents in its GUI session: `hermes gateway` (cron,
kanban dispatch) and `hermes serve` on `127.0.0.1:9119` for Hermes Desktop.
Config and profiles are set up by hand as agent; restart the agents after
changing them (`launchctl kickstart -k
gui/$(id -u)/org.nix-community.home.hermes-gateway`, likewise
`hermes-backend`). Logs: `~/Library/Logs/kit-hermes-*.log`.

The backend's session token is the `hermes backend` item (field `password`)
in the `agent` vault. The backend reads it at start. Hosts with
`kit.hermesDesktop.enable` read it on apply and write Hermes Desktop's default
connection (`~/Library/Application Support/Hermes/connection.json`, only when
missing) to `http://127.0.0.1:9119`. On power the app reaches the backend
directly; elsewhere run `just hermes-tunnel` to forward that port to power
(Ctrl-C to stop). Keep the app at least at the backend's version.

Upgrades: bump the tag in `flake.nix`, `nix flake update hermes-agent`, run
`hermes backup --quick` as agent, apply, then `hermes doctor`. The first build
of each version is long (no binary cache).
