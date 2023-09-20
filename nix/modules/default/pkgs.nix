{ pkgs, config, ... }:

{
  # must have packages
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    tmux
    gnumake
  ];
}
