{ inputs, lib, pkgs, ... }:
{
  imports = with lib.r.modules.user; [
    sops
    helix
    python
    dev
    shell
    atuin
  ];

  home.packages = with pkgs; [
    bash
    vim
    file
    socat

    htop
    fzf
    tmux
  ];

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    # defaultCacheTtl = 1800;
  };
}
