{ pkgs, config, secrets, inputs, lib, ... }:

{
  imports = with inputs.self.systemModules; [
    ./hardware-configuration.nix

    locale
    yggdrasil
    zsh
    zsh-config

    # ca
    ca_rubikoid

    # security
    openssh
    openssh-root-key

    # fs
    ntfs
    zfs

    # hardware
    gigabyte-fans

    # services
    caddy
    memos
    powerdns
    minio
    grafana
    grafana-agent
    akkoma
    mastodon
    ygg-map
    actual
  ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };

    initrd.kernelModules = [ ];
  };

  boot.zfs.extraPools = [
    "backup-drive"
  ];

  networking.hostId = secrets.zfsHostId; # need by zfs

  environment.systemPackages = with pkgs; [
    nix-output-monitor
    vim-full
    tmux
    iotop
    htop
    wget
    curl
    tcpdump
    lm_sensors
    smartmontools
    pciutils # lspci
    usbutils # lsusb
    nix-index # nix-lookup for binary
    ldns # dns help
    moreutils
    jq
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
