{ inputs, lib, pkgs, ... }:
{
  imports =
    with lib.r.modules;
    (with user; [
      shell.shell
    ]);

  home.packages = with pkgs; [
  ];
}
