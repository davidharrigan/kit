{ config, lib, pkgs, ... }:
let
  cfg = config.kit.agent;

  # Claude Code settings, with home paths pointed at agent's.
  claudeSettings = builtins.fromJSON (
    builtins."readFile" ../dots/.claude/settings.json
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
  imports = [ ./hermes.nix ];

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

    home-manager.users.agent = {
      imports = [ ./home.nix ];

      # agent has no checkout of kit, so dotfiles are copies in the Nix store.
      kit.home.liveLinks = false;

      # Non-interactive SSH commands (`herdr --remote` looks up `herdr` this way)
      # read only .zshenv, so put Homebrew on PATH there.
      home.file.".zshenv".text = ''
        export PATH="/opt/homebrew/bin:$PATH"
      '';

      home.file.".claude/settings.json" = lib.mkForce {
        text = builtins.toJSON agentClaudeSettings;
      };
      home.file.".claude/CLAUDE.md" = lib.mkForce {
        text = builtins.readFile ../dots/.claude/CLAUDE.md + agentClaudeMd;
      };

      # Headless Herdr server for agent's default session. Starts when agent logs
      # in to a GUI session (needed for desktop apps and a real browser), and
      # restarts if it exits. Attach with `herdr --remote agent@<host>` or
      # `ssh -t agent@<host> herdr`.
      launchd.agents.herdr = {
        enable = true;
        config = {
          ProgramArguments = [
            "/opt/homebrew/bin/herdr"
            "server"
          ];
          # launchd starts with a bare environment; panes are login shells.
          EnvironmentVariables = {
            SHELL = "${pkgs.zsh}/bin/zsh";
            PATH = "/etc/profiles/per-user/agent/bin:/run/current-system/sw/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin";
            LANG = "en_US.UTF-8";
          };
          WorkingDirectory = "/Users/agent";
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/Users/agent/Library/Logs/kit-herdr.out.log";
          StandardErrorPath = "/Users/agent/Library/Logs/kit-herdr.err.log";
        };
      };
    };
  };
}
