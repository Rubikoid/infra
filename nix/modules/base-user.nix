{ inputs, pkgs, lib, config, secrets, device, mode, ... }:

{
  # programs.home-manager.enable = true; # idk why i need that
  home = {
    username = config.user;
    homeDirectory = "/home/${config.user}"; # TODO: macos
    stateVersion = "24.05";
  };
}
