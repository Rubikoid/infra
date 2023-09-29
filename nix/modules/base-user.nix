{ pkgs, lib, config, ... }:

{
  home = {
    username = config.user;
    homeDirectory = "/home/${config.user}";
    stateVersion = "22.11";
  };
}
