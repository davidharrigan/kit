# Rex (a home-manager module, imported by home.nix): links init.lua
{ config, lib, ... }:
{
  config = lib.mkIf config.kit.home.liveLinks {
    home.file.".config/rex/init.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/src/kit/modules/dots/rex/init.lua";
  };
}
