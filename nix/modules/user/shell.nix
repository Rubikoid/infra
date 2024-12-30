{ pkgs, lib, ... }:
{
  # programs.nushell = {
  #   enable = true;
  # };
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = lib.mkDefault "candy";
      plugins = [
        "git"
        "systemd" 
        "docker"
      ];
    };
  };
}
