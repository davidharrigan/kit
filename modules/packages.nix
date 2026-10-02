# Apps and tools on every host: CLI tools from nixpkgs, fonts, and Homebrew
# formulae/casks. Host-only apps go in hosts/<name>.nix.
{ pkgs, ... }:
{
  # CLI tools, for every user.
  environment.systemPackages = with pkgs; [
    age
    ast-grep
    bat
    d2
    direnv
    fd
    ffmpeg
    fzf
    gcx
    gh
    go-task
    golangci-lint
    helmfile
    himalaya
    hugo
    just
    k9s
    kubectx
    lazygit
    lima
    pipx
    pnpm
    poppler-utils
    pre-commit
    qemu
    rclone
    ripgrep
    sops
    tilt
    tree-sitter
    typst
    yq-go
    zig
  ];

  # Installed into /Library/Fonts/Nix Fonts.
  fonts.packages = with pkgs; [
    nerd-fonts.agave
    nerd-fonts.anonymice
    nerd-fonts.arimo
    nerd-fonts.cousine
    nerd-fonts.envy-code-r
    nerd-fonts.fira-mono
    nerd-fonts.im-writing
    nerd-fonts.inconsolata
    nerd-fonts.sauce-code-pro
    ibm-plex
    monaspace
    roboto
    open-sans
    source-sans
  ];

  # Formulae not packaged in nixpkgs.
  homebrew.brews = [
    "crit"
  ];

  # GUI apps.
  homebrew.casks = [
    "1password"
    "1password-cli"
    "autodesk-fusion"
    "bambu-studio"
    "blender"
    "claude-code@latest"
    "codex"
    # TODO: "docker" is now an alias of "docker-desktop"; drop one.
    "docker"
    "docker-desktop"
    "firefox"
    "ghostty"
    "obsidian"
    "rectangle"
    # Not in nixpkgs; other fonts are in fonts.packages above.
    "font-ioskeley-mono"
  ];
}
