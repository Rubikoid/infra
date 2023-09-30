{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    home-manager
  ];

  # Setup users
  users.users = {
    rubikoid = {
      isNormalUser = true;
      useDefaultShell = true;

      # sudo, docker...
      extraGroups = [ "wheel" "docker" "tss" ];

      openssh.authorizedKeys.keyFiles = [
        config.sops.secrets.ssh.rubikoid.main.path
      ];
    };
  };
}
