{ inputs, pkgs, config, secretsModule, ... }:

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
    firewall = {
      enable = true;
    };
  };

  # system.replaceRuntimeDependencies = [
  #   ({
  #     original = pkgs.xz;
  #     replacement = pkgs.old-xz;
  #   })
  # ];
}
