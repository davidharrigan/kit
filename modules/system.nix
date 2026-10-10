# Machine-wide settings shared by every host: Nix, users, sudo, shell and
# Homebrew itself. Apps are in packages.nix, macOS defaults (per user) in macos.nix.
{ inputs, config, ... }:
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # The user that user-level settings (defaults, homebrew) apply to.
  system.primaryUser = "david";

  # david is an existing macOS account; nix-darwin doesn't create or modify it.
  # home-manager needs the home directory declared here.
  users.users.david.home = "/Users/david";

  # Touch ID for sudo, also inside tmux.
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  # Writes /etc/zshrc etc. so Nix paths are on PATH in zsh.
  programs.zsh.enable = true;
  # ~/.zshrc runs compinit (through Oh My Zsh).
  programs.zsh.enableGlobalCompInit = false;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # Existing regular files in the way are renamed to <file>.before-hm.
    backupFileExtension = "before-hm";
    # Every home-manager user gets the same macOS defaults.
    sharedModules = [ ./macos.nix ];
    users.david = ./home.nix;
  };

  # Installs Homebrew itself and pins its taps to the flake inputs.
  nix-homebrew = {
    enable = true;
    user = config.system.primaryUser;
    # Take over the existing /opt/homebrew install, keeping installed kegs and casks.
    autoMigrate = true;
    # Taps are read-only; `brew tap` can't add more.
    mutableTaps = false;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
  };

  # nix-darwin runs `brew bundle` on every switch with the lists in packages.nix.
  homebrew = {
    enable = true;
    onActivation = {
      # "none" leaves unlisted formulae/casks installed. Switch to "zap" once the lists are complete.
      cleanup = "none";
      autoUpdate = false;
      upgrade = false;
    };
    taps = builtins.attrNames config.nix-homebrew.taps;
  };

  # Read the nix-darwin changelog before changing this.
  system.stateVersion = 7;
}
