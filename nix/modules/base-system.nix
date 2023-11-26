{ inputs, pkgs, config, ... }:

{
  imports = [ inputs.secrets.nixosModules.default ];

  nix = {
    # idk wtf is it, but sounds good;
    optimise.automatic = true;
  };

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
