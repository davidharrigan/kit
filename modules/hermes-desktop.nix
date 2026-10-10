{ config, lib, pkgs, ... }:
{
  options.kit.hermesDesktop.enable = lib.mkEnableOption "Hermes Desktop, connected to power's Hermes backend";

  config = lib.mkIf config.kit.hermesDesktop.enable {
    homebrew.casks = [ "hermes-desktop" ];

    # Hermes Desktop's default connection: power's backend on 127.0.0.1:9119,
    # directly on power and through `just hermes-tunnel` elsewhere. Written
    # once, with the token from 1Password; edits made in the app are kept.
    home-manager.users.david =
      { lib, ... }:
      {
        home.activation.hermesDesktopConnection = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          conn="$HOME/Library/Application Support/Hermes/connection.json"
          if [ ! -e "$conn" ]; then
            if HERMES_TOKEN=$(/opt/homebrew/bin/op read "op://agent/hermes backend/password"); then
              export HERMES_TOKEN
              run mkdir -p "$(dirname "$conn")"
              run sh -c 'umask 077; ${pkgs.jq}/bin/jq -n "{
                mode: \"remote\",
                remote: {
                  url: \"http://127.0.0.1:9119\",
                  authMode: \"token\",
                  token: { encoding: \"plain\", value: env.HERMES_TOKEN }
                },
                profiles: {}
              }" > "$1"' sh "$conn"
              unset HERMES_TOKEN
            else
              warnEcho "Hermes Desktop connection not written: op read failed. Re-run the apply once 1Password is unlocked."
            fi
          fi
        '';
      };
  };
}
