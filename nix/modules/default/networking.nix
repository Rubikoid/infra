{ pkgs, config, ... }:

{
  networking = {
    hostName = config.device;
    firewall = {
      enable = true;
    };
  };
}
