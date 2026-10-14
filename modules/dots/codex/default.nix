# Codex (a home-manager module, imported by home.nix): links keybindings.json
# into ~/.codex and merges config.pinned.toml into ~/.codex/config.toml on
# every switch. Pinned keys overwrite local values; keys not pinned (project
# trust, reasoning effort, for example) are left as Codex wrote them.
{ config, lib, pkgs, ... }:
let
  tomlFormat = pkgs.formats.toml { };
  jsonFormat = pkgs.formats.json { };

  pinned = jsonFormat.generate "codex-config.pinned.json" config.kit.codex.settings;
in
{
  options.kit.codex.settings = lib.mkOption {
    type = tomlFormat.type;
    description = "Settings pinned into ~/.codex/config.toml on every switch.";
  };

  config = lib.mkMerge [
    {
      kit.codex.settings = lib.importTOML ./config.pinned.toml;

      home.activation.codexSettings = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
        dest="$HOME/.codex/config.toml"
        tmp="$(mktemp)"
        if [ -e "$dest" ]; then ${pkgs.remarshal}/bin/toml2json "$dest"; else echo '{}'; fi \
          | ${lib.getExe pkgs.jq} --slurpfile pinned ${pinned} '. * $pinned[0]' \
          | ${pkgs.remarshal}/bin/json2toml > "$tmp"
        run mkdir -p "$(dirname "$dest")"
        run mv -f "$tmp" "$dest"
      '';
    }

    (lib.mkIf config.kit.home.liveLinks {
      home.file.".codex/keybindings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/src/kit/modules/dots/codex/keybindings.json";
    })

    (lib.mkIf (!config.kit.home.liveLinks) {
      home.activation.copyCodex = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        dest="$HOME/.codex/keybindings.json"
        if [ -L "$dest" ]; then run rm "$dest"; fi
        run mkdir -p "$(dirname "$dest")"
        run cp -Lf "${./keybindings.json}" "$dest"
        run chmod u+w "$dest"
      '';
    })
  ];
}
