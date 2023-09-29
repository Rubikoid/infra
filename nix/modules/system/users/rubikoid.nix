{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    home-manager
  ];

  # TODO: Fix
  # Change default shell to zsh
  users.defaultUserShell = pkgs.zsh;

  # Setup users
  users.users = {
    rubikoid = {
      isNormalUser = true;
      useDefaultShell = true;

      # sudo, docker...
      extraGroups = [ "wheel" "docker" "tss" ];

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOXNeouqZX2g3lYGgI+R9kGOBGPhV+cOvXOHPxKRygKl rubikoid@rubikoid.ru"
      ];
    };
  };
}
