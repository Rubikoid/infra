{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nil
    nixpkgs-fmt

    ripgrep

    lazygit

    k9s
    kubectl
  ];
}
