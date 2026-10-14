{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.kit.agent;

  # Hermes Agent is installed by its official installer (into
  # ~/.hermes/hermes-agent, command at ~/.local/bin/hermes) and updates itself
  # with `hermes update`. Nix only runs the services.
  hermes = "/Users/agent/.local/bin/hermes";

  # A launchd agent for agent's GUI session that restarts if it exits; logs go
  # to ~/Library/Logs/kit-<name>.*.log.
  sessionAgent = name: args: {
    enable = true;
    config = {
      ProgramArguments = args;
      # launchd starts with a bare environment.
      EnvironmentVariables = {
        SHELL = "${pkgs.zsh}/bin/zsh";
        PATH = "/Users/agent/.local/bin:/etc/profiles/per-user/agent/bin:/run/current-system/sw/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        LANG = "en_US.UTF-8";
      };
      WorkingDirectory = "/Users/agent";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/Users/agent/Library/Logs/kit-${name}.out.log";
      StandardErrorPath = "/Users/agent/Library/Logs/kit-${name}.err.log";
    };
  };

  # Hermes gateway (cron, kanban dispatch). Exports the 1Password service
  # account token so Hermes' op:// secret lookups work, same as the backend.
  hermesGateway = pkgs.writeShellScript "hermes-gateway" ''
    set -euo pipefail
    OP_SERVICE_ACCOUNT_TOKEN=$(cat "$HOME/.config/op/service-account-token")
    export OP_SERVICE_ACCOUNT_TOKEN
    exec ${hermes} gateway
  '';

  # Hermes Desktop's backend, also serving the web UI dashboard. Its session
  # token comes from the agent vault at start, so it stays out of the Nix
  # store. OP_SERVICE_ACCOUNT_TOKEN stays exported for Hermes' own 1Password
  # secret lookups.
  hermesBackend = pkgs.writeShellScript "hermes-backend" ''
    set -euo pipefail
    OP_SERVICE_ACCOUNT_TOKEN=$(cat "$HOME/.config/op/service-account-token")
    export OP_SERVICE_ACCOUNT_TOKEN
    HERMES_DASHBOARD_SESSION_TOKEN=$(/opt/homebrew/bin/op read "op://agent/hermes backend/password")
    export HERMES_DASHBOARD_SESSION_TOKEN
    exec ${hermes} dashboard --host 127.0.0.1 --port 9119 --no-open
  '';

  # Restarts the Hermes launchd agents: `hermes-restart {backend|gateway|all}`.
  hermesRestart = pkgs.writeShellScriptBin "hermes-restart" ''
    set -euo pipefail
    case "''${1:-}" in
      all) names="backend gateway" ;;
      backend|gateway) names="$1" ;;
      *) echo "usage: hermes-restart {backend|gateway|all}" >&2; exit 1 ;;
    esac
    for n in $names; do
      launchctl kickstart -k "gui/$(id -u)/org.nix-community.home.hermes-$n"
    done
  '';

  # Claude Code settings, with home paths pointed at agent's.
  claudeSettings = builtins.fromJSON (
    builtins."readFile" ./dots/claude/settings.pinned.json
  );

  # agent runs unattended, so no permission prompts. Remote Control makes each
  # session reachable from claude.ai and the Claude app.
  agentClaudeSettings = builtins.removeAttrs claudeSettings [ "autoMode" ] // {
    permissions = builtins.removeAttrs claudeSettings.permissions [ "ask" ] // {
      defaultMode = "bypassPermissions";
    };
    skipDangerousModePermissionPrompt = true;
    remoteControlAtStartup = true;
  };

  agentClaudeMd = ''

    ## Agent environment
    You run as the `agent` macOS user, usually unattended inside a Herdr
    session. Permission prompts are off, so act carefully.

    - **GitHub**: `gh` and git over SSH are signed in as `takohoncho`.
    - **Secrets**: the 1Password CLI `op` is signed in with a service account
      (`OP_SERVICE_ACCOUNT_TOKEN`, exported by ~/.zshrc). It has read-only
      access to the `agent` vault, and nothing else.
      - List: `op item list --vault agent`
      - Read one field: `op read "op://agent/<item>/<field>"`
      - Run with secrets in env: `op run --env-file=<file> -- <cmd>`, where the
        file holds `NAME=op://agent/<item>/<field>` references.
      - Pass secrets to commands through `op run` or `$(op read …)`. Never echo
        them, write them to files, or commit them.
      - If a credential you need isn't in the vault, stop and ask the user to add it.
    - **Network**: TCP/UDP to 192.168.0.0/16 is blocked; the local network is
      unreachable by design.
    - **Privileges**: agent is not an admin; `sudo` is unavailable.
  '';
in
{
  options.kit.agent.enable = lib.mkEnableOption "an `agent` user";

  config = lib.mkIf cfg.enable {
    # Only users listed in knownUsers are created (and deleted) by nix-darwin.
    users.knownUsers = [ "agent" ];
    users.users.agent = {
      uid = 510;
      gid = 20; # staff
      isHidden = false;
      home = "/Users/agent";
      createHome = true;
      shell = pkgs.zsh;
      description = "Agent";
    };

    # Fast user switching, with its menu in the menu bar for every user, to move
    # between agent's GUI session and the others.
    system.defaults.CustomSystemPreferences.".GlobalPreferences".MultipleSessionEnabled = true;
    home-manager.sharedModules = [
      {
        # 2 = show in menu bar.
        targets.darwin.currentHostDefaults."com.apple.controlcenter".UserSwitcher = 2;
      }
    ];

    # Block agent's TCP/UDP traffic to the local network. Loaded into a sub-anchor
    # of com.apple/*, which the stock /etc/pf.conf already evaluates.
    launchd.daemons.agent-pf = {
      script = ''
        /sbin/pfctl -E
        /sbin/pfctl -a com.apple/kit-agent -f ${pkgs.writeText "agent.pf" ''
          block return out quick proto { tcp udp } from any to 192.168.0.0/16 user agent
        ''}
      '';
      serviceConfig.RunAtLoad = true;
    };

    home-manager.users.agent = { lib, ... }: {
      imports = [ ./home.nix ];

      # agent has no checkout of kit, so dotfiles are copied into its home as
      # writable files (Claude Code, for one, rewrites its settings.json).
      kit.home.liveLinks = false;

      # Non-interactive SSH commands (`herdr --remote` looks up `herdr` this way)
      # read only .zshenv, so put Homebrew and ~/.local/bin (the Hermes
      # installer's commands) on PATH there.
      home.file.".zshenv".text = ''
        export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
      '';

      # Commit as takohoncho, the account gh and git push as. Git reads
      # ~/.gitconfig after the shared ~/.config/git/config, so this wins.
      home.file.".gitconfig".text = ''
        [user]
          name = takohoncho
          email = 317447273+takohoncho@users.noreply.github.com
      '';

      # Replace the copied Claude Code files with agent's versions.
      home.activation.agentClaude = lib.hm.dag.entryAfter [ "copyDots" "copyClaude" ] ''
        run install -m 644 ${pkgs.writeText "settings.json" (builtins.toJSON agentClaudeSettings)} "$HOME/.claude/settings.json"
        run install -m 644 ${
          pkgs.writeText "CLAUDE.md" (builtins.readFile ./dots/claude/CLAUDE.md + agentClaudeMd)
        } "$HOME/.claude/CLAUDE.md"
      '';

      # Headless Herdr server for agent's default session. Starts when agent logs
      # in to a GUI session (needed for desktop apps and a real browser), and
      # restarts if it exits. Attach with `herdr --remote agent@<host>` or
      # `ssh -t agent@<host> herdr`.
      launchd.agents.herdr = sessionAgent "herdr" [
        "/opt/homebrew/bin/herdr"
        "server"
      ];

      # Hermes: the gateway (cron, kanban dispatch) and the backend Hermes
      # Desktop and the web dashboard use on 127.0.0.1:9119 (`just
      # hermes-tunnel` from a laptop).
      # Restart them after config changes with `hermes-restart`.
      home.packages = [ hermesRestart ];
      launchd.agents.hermes-gateway = sessionAgent "hermes-gateway" [ "${hermesGateway}" ];
      launchd.agents.hermes-backend = sessionAgent "hermes-backend" [ "${hermesBackend}" ];
    };
  };
}
