{ config, secrets, pkgs, lib, mode, ... }:

{
  # Setup users
  users.users = {
    rubikoid = lib.mkMerge [
      {
        openssh.authorizedKeys.keys = [ secrets.ssh.rubikoid.main ];
      }
      (lib.mkIf (mode == "NixOS") {
        isNormalUser = true;
        useDefaultShell = true;

        extraGroups = [ "wheel" "docker" "tss" ];
      })
      (lib.mkIf (mode == "Darwin") {
        # https://github.com/nix-community/home-manager/issues/4026
        # https://github.com/LnL7/nix-darwin/issues/682
        # ????
        home = "/Users/rubikoid";
      })
    ];
  };
}
