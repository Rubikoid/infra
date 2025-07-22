{
  pkgs,
  config,
  inputs,
  secrets,
  lib,
  ...
}:

{
  imports = lib.lists.flatten (
    with lib.r.modules.system;
    [
      compact
      orbstack
      yggdrasil
      hm

      ca.rubikoid
      # users.rubikoid

      (with other; [
        remote-build
      ])
    ]
  );

  nix.optimise.automatic = true;

  environment.systemPackages = with pkgs; [
    rsync
    wireguard-tools
    netbird
  ];

  system.stateVersion = "25.11"; # Did you read the comment?
}
