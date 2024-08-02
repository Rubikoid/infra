{ inputs, lib, pkgs, config, secretsModule, my-lib, ... }:

{
  imports = [ secretsModule ];

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
}
