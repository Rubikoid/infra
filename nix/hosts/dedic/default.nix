{ pkgs, config, inputs, lib, ... }:

{
  imports = with inputs.self.systemModules; [
    ./hardware-configuration.nix

    compact
    locale
    yggdrasil
    zsh
    zsh-config

    # ca
    ca_rubikoid

    # security
    openssh
    openssh-root-key

    # services
    step-ca

    # other
    in-proxmox-lxc

    # local
    ./docker.nix
  ];

  proxmoxLXC = {
    manageNetwork = false;
    privileged = false;
    manageHostName = true;
  };

  services.yggdrasil = {
    openMulticastPort = false;

    settings = {
      MulticastInterfaces = lib.mkForce [ ];
    };
  };

  environment.systemPackages = with pkgs; [
    htop
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
