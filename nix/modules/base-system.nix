{ inputs, lib, pkgs, config, secretsModule, ... }:

{
  imports = [ secretsModule ];

  # must have packages
  environment.systemPackages = with pkgs; [
    vim
    git
    gnumake
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
