# Host-specific settings: hostname, optional features, host-only apps.
{
  networking.hostName = "chainsaw";

  kit.ssh.enable = false;
  kit.alwaysOn.enable = false;
  kit.agent.enable = false;

  homebrew.casks = [
    "bartender"
    "hermes-desktop" # connects to power's Hermes backend over an SSH tunnel
  ];
}
