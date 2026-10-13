# Dotfiles (a home-manager module, used by system.nix and agent.nix): links or
# copies everything in dots/ into $HOME.
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
  # rebuild.
  link = rel: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/src/kit/dots/${rel}";

  # Copies are real, writable files, overwritten on every switch. Symlinks
  # inside dots/ are copied as what they point to.
  copy = rel: ''
    dest="$HOME/${rel}"
    if [ -L "$dest" ]; then run rm "$dest"; fi
    run mkdir -p "$(dirname "$dest")"
  '' + (
    if lib.elem rel wholeDirs then ''
      run mkdir -p "$dest"
      run cp -RLf "${dots}/${rel}/." "$dest/"
    '' else ''
      run cp -Lf "${dots}/${rel}" "$dest"
    ''
  ) + ''
    run chmod -R u+w "$dest"
  '';

  # Paths under dots/ to link or copy. The flake only sees git-tracked files.
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
    description = "Link dotfiles to ~/src/kit instead of copying them into $HOME.";
  };

  config = lib.mkMerge [
    (lib.mkIf config.kit.home.liveLinks {
      home.file = lib.genAttrs (walk "") (rel: {
        source = link rel;
      });
    })

    (lib.mkIf (!config.kit.home.liveLinks) {
      home.activation.copyDots = lib.hm.dag.entryAfter [ "linkGeneration" ] (
        lib.concatMapStrings copy (walk "")
      );
    })

    { home.stateVersion = "26.05"; }
  ];
}
