{ pkgs, config, ... }:

{
  # must have packages
  environment.systemPackages = with pkgs; [
    vim-full
    git
    curl
    tmux
  ];
}
