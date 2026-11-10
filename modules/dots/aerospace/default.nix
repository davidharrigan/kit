# AeroSpace (a home-manager module, imported by home.nix): links aerospace.toml
# into ~/.config/aerospace. The app itself is a Homebrew cask in hosts/chainsaw.nix.
{ config, lib, ... }:
{
  config = lib.mkIf config.kit.home.liveLinks {
    home.file.".config/aerospace/aerospace.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/src/kit/modules/dots/aerospace/aerospace.toml";
  };
}
