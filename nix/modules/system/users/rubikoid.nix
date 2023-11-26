{ config, secrets, pkgs, ... }:

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

      openssh.authorizedKeys.keys = [ secrets.ssh.rubikoid.main ];
    };
  };
}
