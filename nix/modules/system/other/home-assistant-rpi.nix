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
    services.ha = {
      enable = true;

    };
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
    htop
  ];

  networking.hosts = {
    # на случай проблем с DNS
    secrets.dns.data.nodes.kubc.at.ygg = [ secrets.harmonia.addr ];
  };

  hardware = {
    enableAllHardware = lib.mkForce false;

    raspberry-pi."4" = {
      apply-overlays-dtmerge.enable = true;
    };
  };

  boot.supportedFilesystems = [
    "vfat"
  ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
