{ inputs, pkgs, lib, ... }:
{
  imports = with lib.r.modules.user; [
    helix
    shell
  ];

  home.packages = with pkgs; [

  ];
}
