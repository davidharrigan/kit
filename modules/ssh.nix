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
      }
      (lib.mkIf config.kit.agent.enable {
        users.users.agent.openssh.authorizedKeys.keys = cfg.authorizedKeys;
      })
    ]
  );
}
