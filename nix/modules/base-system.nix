{ inputs, lib, pkgs, config, secretsModule, ... }:
let
  cfg = config.rubikoid;
in
{
  imports = [ secretsModule ];

  config = {
    secrets.enable = lib.mkDefault true;

    # must have packages
    environment.systemPackages = with pkgs; [
      vim
      git
      just
    ];

    networking = {
      hostName = lib.r.strace config.device;
    };

    # system.replaceRuntimeDependencies = [
    #   ({
    #     original = pkgs.xz;
    #     replacement = pkgs.old-xz;
    #   })
    # ];
  };
}
