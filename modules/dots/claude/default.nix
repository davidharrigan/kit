# Claude Code (a home-manager module, imported by home.nix): links the files
# here into ~/.claude and merges settings.pinned.json into
# ~/.claude/settings.json on every switch. Pinned keys overwrite local values;
# keys not pinned (effort level, for one) are left as Claude Code wrote them.
{ config, lib, pkgs, ... }:
let
  jsonFormat = pkgs.formats.json { };

  # Linked into ~/.claude, or copied when kit.home.liveLinks is off.
  entries = [
    "CLAUDE.md"
    "cmdhook.toml"
    "statusline-command.sh"
    "agents"
    "commands"
    "hooks"
    "skills"
  ];

  link = rel: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/src/kit/modules/dots/claude/${rel}";

  copy = rel: ''
    dest="$HOME/.claude/${rel}"
    if [ -L "$dest" ]; then run rm "$dest"; fi
    run mkdir -p "$(dirname "$dest")"
  '' + (
    if lib.pathIsDirectory (./. + "/${rel}") then ''
      run mkdir -p "$dest"
      run cp -RLf "${./.}/${rel}/." "$dest/"
    '' else ''
      run cp -Lf "${./.}/${rel}" "$dest"
    ''
  ) + ''
    run chmod -R u+w "$dest"
  '';

  pinned = jsonFormat.generate "claude-settings.pinned.json" config.kit.claude.settings;
in
{
  options.kit.claude.settings = lib.mkOption {
    type = jsonFormat.type;
    description = "Settings pinned into ~/.claude/settings.json on every switch.";
  };

  config = lib.mkMerge [
    {
      kit.claude.settings = lib.importJSON ./settings.pinned.json;

      # Runs before linkGeneration so a settings.json still linked by the
      # previous generation is read before home-manager removes the link.
      home.activation.claudeSettings = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
        dest="$HOME/.claude/settings.json"
        tmp="$(mktemp)"
        if [ -e "$dest" ]; then cat "$dest"; else echo '{}'; fi \
          | ${lib.getExe pkgs.jq} --slurpfile pinned ${pinned} '. * $pinned[0]' > "$tmp"
        run mkdir -p "$(dirname "$dest")"
        run mv -f "$tmp" "$dest"
      '';
    }

    (lib.mkIf config.kit.home.liveLinks {
      home.file = lib.listToAttrs (
        map (e: lib.nameValuePair ".claude/${e}" { source = link e; }) entries
      );
    })

    (lib.mkIf (!config.kit.home.liveLinks) {
      home.activation.copyClaude = lib.hm.dag.entryAfter [ "linkGeneration" ] (
        lib.concatMapStrings copy entries
      );
    })
  ];
}
