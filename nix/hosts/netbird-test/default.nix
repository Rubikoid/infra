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

      ca.rubikoid

      (with other; [
        remote-build
      ])
    ]
  );

  nix.optimise.automatic = true;

  environment.systemPackages = with pkgs; [
    rsync
    wireguard-tools
  ];

  system.stateVersion = "24.05"; # Did you read the comment?
}
