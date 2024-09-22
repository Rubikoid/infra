{ pkgs, config, inputs, secrets, lib, ... }:

{
  imports = with inputs.self.systemModules; [
    compact
    orbstack

    # ca
    ca_rubikoid

    # other
    remote-build
  ];

  environment.systemPackages = with pkgs; [
    rsync
    wireguard-tools
  ];

  networking.hosts = {
    "192.168.1.107" = [ "kubic.nodes.internal.rubikoid.ru" ];
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
