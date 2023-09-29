{ inputs, pkgs, lib, config, ... }:

{
  imports = [ inputs.sops-nix.homeManagerModule ];

  home = {
    username = config.user;
    homeDirectory = "/home/${config.user}";
    stateVersion = "22.11";
  };
}
