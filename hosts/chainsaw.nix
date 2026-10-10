# Host-specific settings: hostname, optional features, host-only apps.
{ ... }:
{
  networking.hostName = "chainsaw";

  kit.ssh.enable = false;
  kit.alwaysOn.enable = false;
  kit.agent.enable = false;
  kit.hermesDesktop.enable = true;

  homebrew.casks = [
    "bartender"
  ];
}
