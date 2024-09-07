{ inputs, lib, pkgs, config, secretsModule, my-lib, ... }:
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
      hostName = my-lib.strace config.device;
    };

    # system.replaceRuntimeDependencies = [
    #   ({
    #     original = pkgs.xz;
    #     replacement = pkgs.old-xz;
    #   })
    # ];
  };
}
