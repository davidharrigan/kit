# Manual steps

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

Enable it as david: `sudo fdesetup enable` (or System Settings → Privacy &
Security → FileVault).

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

nix-darwin creates `agent` as a hidden standard user (no admin, no sudo)
without a password or SecureToken, so it can't unlock FileVault. Its job
(`launchd.agents.agent` in `modules/agent.nix`) runs inside its GUI session, which
desktop apps (e.g. Tauri) and a real browser need.

- Set a password so it can log in: `sudo dscl . -passwd /Users/agent`.
- Enable Screen Sharing (System Settings → General → Sharing).
- After each reboot: unlock FileVault over SSH as david, then log agent in via
  Screen Sharing. If david is on the console, choose to log in as agent in a
  separate virtual session. Auto-login isn't possible with FileVault on.
- Act as it from a shell: `sudo -u agent -i`.
- Give it its own SSH/GitHub key: `ssh-keygen -t ed25519` as agent, then add
  the public key to GitHub.
- Login keychain unlocks with its GUI login; `sudo -u agent` shells don't get it.
- Git identity comes from the shared git config (david's). Override it for
  agent if needed.
- Install Oh My Zsh for it (see README, fresh server).
