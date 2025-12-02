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
      yggdrasil
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

  nix.package = lib.mkForce pkgs.lix;

  networking.hosts = {
    # ${secrets.dns.data.nodes.kubic.at.wg} = [ "kubic.nodes.${secrets.dns.private}" ];
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
