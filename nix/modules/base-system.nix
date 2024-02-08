{ inputs, pkgs, config, secretsModule, ... }:

{
  imports = [ secretsModule ];

  # must have packages
  environment.systemPackages = with pkgs; [
    vim
    git
    gnumake
  ];

  networking = {
    hostName = config.device;
    firewall = {
      enable = true;
    };
  };
}
