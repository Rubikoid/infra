{ inputs, pkgs, lib, ... }:
{
  imports = lib.lists.flatten (
    with lib.r.modules.user;
    [
      helix

      shell.shell
      (with shell.soft; [
        tmux
        atuin
        zoxide
        pay-respects
      ])
    ]
  );

  home.packages = with pkgs; [

  ];
}
