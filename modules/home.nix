# Dotfiles (a home-manager module, used by system.nix and agent.nix): links
# everything in dots/ into $HOME.
{ config, lib, ... }:
let
  dots = ../dots;

  # Not linked into $HOME.
  skip = [
    ".homebrew"
    ".codex"
  ];

  # Linked as whole directories: new files show up without a switch. Everything
  # else is linked file by file, so real directories such as ~/.ssh, ~/.claude
  # and ~/.config keep their local contents (like stow does).
  wholeDirs = [
    ".agents"
    ".env"
    ".completion"
    ".config/nvim"
    ".claude/agents"
    ".claude/commands"
    ".claude/hooks"
    ".claude/skills"
  ];

  # Live links point at the checkout in ~/src/kit, so edits apply without a
  # rebuild. Otherwise the file is copied into the Nix store at build time.
  link =
    rel:
    if config.kit.home.liveLinks then
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/src/kit/dots/${rel}"
    else
      dots + "/${rel}";

  # Paths under dots/ to link. The flake only sees git-tracked files.
  walk =
    dir:
    lib.concatLists (
      lib.mapAttrsToList (
        name: type:
        let
          rel = if dir == "" then name else "${dir}/${name}";
        in
        if lib.elem rel skip then
          [ ]
        else if type == "directory" && !(lib.elem rel wholeDirs) then
          walk rel
        else
          [ rel ]
      ) (builtins.readDir (if dir == "" then dots else dots + "/${dir}"))
    );
in
{
  options.kit.home.liveLinks = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Link dotfiles to ~/src/kit instead of the Nix store.";
  };

  config = {
    home.file = lib.genAttrs (walk "") (rel: {
      source = link rel;
    });

    home.stateVersion = "26.05";
  };
}
