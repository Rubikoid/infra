{ pkgs, lib, secrets, config, ... }:

{
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  users.groups.nix-builder = { };
  users.users.nix-builder = {
    description = "Nix Remote Builder";
    isNormalUser = true;
    shell = pkgs.bashInteractive; # pkgs.shadow;
    openssh.authorizedKeys.keys = secrets.ssh.nix-builder;
    group = config.users.groups.nix-builder.name;
  };

  nix.settings.trusted-users = [ "nix-builder" ];

  programs.ccache.enable = true;
  nix.settings.extra-sandbox-paths = [ config.programs.ccache.cacheDir ];
}
