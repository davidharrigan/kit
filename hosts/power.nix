# Host-specific settings: hostname, optional features, host-only apps.
{
  networking.hostName = "power";

  kit.ssh.enable = true;
  kit.ssh.authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM/z/gtwGhU9txZ4kH1ZeO1tKgr2W318RCuHGa0dIs3l davidharrigan@users.noreply.github.com" # chainsaw
  ];
  kit.alwaysOn.enable = true;
  kit.agent.enable = true;

  homebrew.casks = [
    "ollama-app"
  ];
}
