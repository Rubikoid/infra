{ inputs, pkgs, ... }:
{
  imports = with inputs.self.userModules; [
    sops
    helix
    python
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
  ];

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    # defaultCacheTtl = 1800;
  };
}

