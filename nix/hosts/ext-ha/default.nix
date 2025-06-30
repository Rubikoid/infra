{
  pkgs,
  config,
  secrets,
  inputs,
  lib,
  utils,
  ...
}:

{
  imports = lib.lists.flatten (
    with lib.r.modules.system;
    [
      "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image.nix"
      "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"

      inputs.nixos-hardware.nixosModules.raspberry-pi-4

      zsh
      locale
      yggdrasil

      services.ha

      ca.rubikoid
      users.rubikoid

      (with other; [
        remote-build
      ])

      (with security; [
        openssh
        openssh-root-key
      ])
    ]
  );

  disabledModules = [
    "profiles/all-hardware.nix"
    "profiles/base.nix" # goddam fucking ZFS WTF???
  ];

  rubikoid = {
    zsh.omz = true;
  };

  environment.systemPackages = with pkgs; [
    vim
    sdparm
    hdparm
    smartmontools
    pciutils
    usbutils
    mmc-utils

    python312Packages.universal-silabs-flasher

    raspberrypi-eeprom
    lm_sensors
  ];

  hardware = {
    enableAllHardware = lib.mkForce false;

    deviceTree.filter = "bcm2711-rpi-cm4.dtb";

    raspberry-pi."4" = {
      apply-overlays-dtmerge.enable = true;

      dwc2 = {
        enable = true;
        dr_mode = "host";
      };

      xhci.enable = true;
    };
  };

  boot.supportedFilesystems = [
    "vfat"
  ];
  networking.useDHCP = true;

  system.stateVersion = "24.11"; # Did you read the comment?
}
