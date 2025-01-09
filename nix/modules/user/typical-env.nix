{ inputs, pkgs, lib, ... }:
{
  imports = with lib.r.modules.user; [
    sops
    helix
    python
    dev
    atuin
    shell
  ];

  home.packages = with pkgs; [

  ];
}
