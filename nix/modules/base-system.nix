{ inputs, lib, pkgs, config, secretsModule, ... }:

{
  imports = [ secretsModule ];

  # must have packages
  environment.systemPackages = with pkgs; [
    vim
    git
    just
  ];

  networking = {
    hostName = config.device;
  };

  # system.replaceRuntimeDependencies = [
  #   ({
  #     original = pkgs.xz;
  #     replacement = pkgs.old-xz;
  #   })
  # ];
}
