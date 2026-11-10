# Host-specific settings: hostname, optional features, host-only apps.
{ pkgs, ... }:
{
  networking.hostName = "chainsaw";

  kit.ssh.enable = false;
  kit.alwaysOn.enable = false;
  kit.agent.enable = false;
  kit.hermesDesktop.enable = true;

  # Started by AeroSpace's after-startup-command.
  environment.systemPackages = [ pkgs.jankyborders ];

  homebrew.casks = [
    "bartender"
    "nikitabobko/tap/aerospace"
  ];
}
