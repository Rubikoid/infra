{ inputs, lib, pkgs, ... }:
{
  imports = with lib.r.modules.user; [
    typical-env
  ];

  home.packages = with pkgs; [
    bash
    vim
    file
    socat

    htop
    fzf
  ];

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    # defaultCacheTtl = 1800;
  };
}
