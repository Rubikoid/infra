{ inputs, pkgs, ... }:
{
  imports = with inputs.self.userModules; [
    sops
  ];

  home.packages = with pkgs; [
    bash
    vim
    file
    socat
    nil
    nixpkgs-fmt
    htop
    fzf
    tmux
    helix
    sops
  ];

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    # defaultCacheTtl = 1800;
  };
}

