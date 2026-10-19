# Dotfiles (a home-manager module, used by system.nix and agent.nix): links or
# copies everything in dots/ into $HOME, plus the per-tool modules in
# modules/dots/.
{ config, lib, ... }:
let
  dots = ../dots;

  # Not linked into $HOME.
  skip = [
    ".homebrew"
  ];

  # Linked as whole directories: new files show up without a switch. Everything
  # else is linked file by file, so real directories such as ~/.ssh, ~/.claude
  # and ~/.config keep their local contents (like stow does).
  wholeDirs = [
    ".agents"
    ".env"
    ".completion"
    ".config/nvim"
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
  imports = [
    ./dots/claude
    ./dots/codex
  ];

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

    {
      # Installs the plugins listed in dots/.config/herdr/plugins.list when
      # missing. Herdr comes from Homebrew; a failed install doesn't fail the
      # switch.
      home.activation.herdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        herdr=/opt/homebrew/bin/herdr
        if [ -x "$herdr" ]; then
          installed="$("$herdr" plugin list 2>/dev/null || true)"
          while read -r plugin ref; do
            case "$plugin" in ""|"#"*) continue ;; esac
            if ! printf '%s\n' "$installed" | grep -qiF "github:$plugin@"; then
              run "$herdr" plugin install --yes ''${ref:+--ref "$ref"} "$plugin" \
                || echo "herdr plugin $plugin failed to install" >&2
            fi
          done < ${dots}/.config/herdr/plugins.list
        fi
      '';

      home.stateVersion = "26.05";
    }
  ];
}
