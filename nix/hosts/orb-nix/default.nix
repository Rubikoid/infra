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
    ${secrets.dns.data.nodes.kubic.at_home} = [ "kubic.nodes.${secrets.dns.private}" ];
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
