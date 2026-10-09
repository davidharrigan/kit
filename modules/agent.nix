{ config, lib, pkgs, ... }:
let
  cfg = config.kit.agent;
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

    home-manager.users.agent = {
      imports = [ ./home.nix ];

      # agent has no checkout of kit, so dotfiles are copies in the Nix store.
      kit.home.liveLinks = false;

      # Starts when agent logs in to a GUI session (needed for desktop apps and a
      # real browser), and restarts if it exits.
      launchd.agents.agent = {
        enable = true;
        config = {
          # TODO: replace with the real agent command.
          ProgramArguments = [
            "/bin/sh"
            "-c"
            "while true; do echo agent placeholder; sleep 3600; done"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/Users/agent/Library/Logs/kit-agent.out.log";
          StandardErrorPath = "/Users/agent/Library/Logs/kit-agent.err.log";
        };
      };
    };
  };
}
