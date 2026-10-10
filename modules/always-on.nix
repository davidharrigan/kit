{ config, lib, ... }:
{
  options.kit.alwaysOn.enable = lib.mkEnableOption "never sleeping and coming back after power loss";

  config = lib.mkIf config.kit.alwaysOn.enable {
    power.sleep.computer = "never";
    power.sleep.harddisk = "never";
    power.restartAfterPowerFailure = true;
    networking.wakeOnLan.enable = true;
  };
}
