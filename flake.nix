{
  description = "kit: macOS machines managed with nix-darwin and home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Homebrew taps pinned by flake.lock (plain git repos, not flakes).
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs =
    inputs@{ nixpkgs, nix-darwin, ... }:
    let
      # Every host gets the shared modules plus hosts/<name>.nix.
      mkHost =
        host:
        nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./modules/system.nix
            ./modules/packages.nix
            ./modules/ssh.nix
            ./modules/always-on.nix
            ./modules/agent.nix
            ./modules/hermes-desktop.nix
            ./hosts/${host}.nix
          ];
        };
    in
    {
      darwinConfigurations = nixpkgs.lib.genAttrs [
        "chainsaw"
        "power"
      ] mkHost;
    };
}
