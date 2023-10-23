{ pkgs, config, inputs, lib, ... }:

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

  ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };

    initrd.kernelModules = [ ];
    # binfmt.emulatedSystems = [ "aarch64-linux" ]; # need to add this to build images for rpi

    supportedFilesystems = [ "ntfs" ];
  };

  environment.systemPackages = with pkgs; [
    tmux
    iotop
    htop
    tcpdump
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    gnumake
    curl
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
