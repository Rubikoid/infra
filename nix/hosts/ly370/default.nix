{ inputs, pkgs, lib, ... }:

{
  imports = with inputs.self.systemModules; [
    ./hardware-configuration.nix

    graphics
    locale
    wireless
    yggdrasil
    zsh

    # ca
    ca_bk252
    ca_rubikoid

    # security
    openssh
    ssh-agent
    tpm

    # users
    rubikoid

    # other
    ios
    split-dns
    thinkfan
  ];

  # extra boot
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = false;

    initrd.kernelModules = [ ];
    binfmt.emulatedSystems = [ "aarch64-linux" ]; # need to add this to build images for rpi

    # kernelPackages = pkgs.linuxPackages_latest;
    # loader.efi.efiSysMountPoint = "/boot/efi";

    supportedFilesystems = [ "ntfs" ];
  };

  # TODO: you knew
  environment.systemPackages = with pkgs; [
    vim-full
    wget
    git
    curl
    tmux
    gcc
    zsh
    htop
    ncdu
    neofetch
    fzf
  ];

  networking = {
    firewall = {
      allowedTCPPorts = [
        22000
      ];
    };
    wireless = {
      enable = true; # Enables wireless support via wpa_supplicant.
      userControlled.enable = true;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
