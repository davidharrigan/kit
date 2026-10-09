{ config, lib, ... }:
let
  cfg = config.kit.ssh;
  # Accounts allowed to log in over SSH.
  sshUsers = [ "david" ] ++ lib.optional config.kit.agent.enable "agent";
in
{
  options.kit.ssh = {
    enable = lib.mkEnableOption "the SSH server with key-only login";
    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Public keys allowed to ssh";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # With password login off, an empty key list would lock out remote access.
        assertions = [
          {
            assertion = cfg.authorizedKeys != [ ];
            message = "kit.ssh.authorizedKeys is empty; set it in the host file.";
          }
        ];

        services.openssh.enable = true;
        # Written to /etc/ssh/sshd_config.d/100-nix-darwin.conf.
        services.openssh.extraConfig = ''
          PasswordAuthentication no
          KbdInteractiveAuthentication no
          PermitRootLogin no
          AllowUsers ${lib.concatStringsSep " " sshUsers}
        '';

        users.users.david.openssh.authorizedKeys.keys = cfg.authorizedKeys;

        # Each SSH user gets its own key pair, generated once if missing.
        home-manager.users = lib.genAttrs sshUsers (
          user:
          { lib, ... }:
          {
            home.activation.sshKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              if [ ! -e "$HOME/.ssh/id_ed25519" ]; then
                run mkdir -p -m 700 "$HOME/.ssh"
                run /usr/bin/ssh-keygen -q -t ed25519 -N "" \
                  -C "${user}@${config.networking.hostName}" -f "$HOME/.ssh/id_ed25519"
              fi
            '';
          }
        );
      }
      (lib.mkIf config.kit.agent.enable {
        users.users.agent.openssh.authorizedKeys.keys = cfg.authorizedKeys;

        # When Remote Login is limited to some users, macOS also requires
        # membership in com.apple.access_ssh; add agent to it.
        system.activationScripts.postActivation.text = ''
          if dscl . -read /Groups/com.apple.access_ssh &>/dev/null &&
            ! dseditgroup -o checkmember -m agent com.apple.access_ssh &>/dev/null; then
            echo "adding agent to com.apple.access_ssh..." >&2
            dseditgroup -o edit -a agent -t user com.apple.access_ssh
          fi
        '';
      })
    ]
  );
}
