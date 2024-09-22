# Profile for virtual machines on Yandex Cloud, intended for disk images.
#
# 
# base on cloud-yandex.nix from tvix

{ config, lib, pkgs, modulesPath, ... }:

let
  cfg = config.virtualisation.selectelCloud;

  # Kernel modules required for interacting with the hypervisor. These
  # must be available during stage 1 boot and during normal operation,
  # as disks and network do not work without them.
  modules = [
    "virtio-net"
    "virtio-blk"
    "virtio-pci"
    "virtio-gpu" # c-p from live system
    "virtio-console" # c-p from live system
    "virtio-balloon" # c-p from live system
    "virtio-rng" # c-p from live system
    "virtio-scsi" # c-p from live system
    "virtiofs"
  ];
in
{
  imports = [
    "${modulesPath}/profiles/headless.nix"
  ];

  options = {
    virtualisation.selectelCloud = {
      rootPartitionUuid = with lib; mkOption {
        type = types.str;
        default = "C55A5EE2-E5FA-485C-B3AE-CC928429AB6B";

        description = ''
          UUID to use for the root partition of the disk image. Yandex
          Cloud requires that root partitions are mounted by UUID.

          Most users do not need to set this to a non-default value.
        '';
      };
    };
  };

  config = {
    fileSystems."/" = {
      device = "/dev/disk/by-uuid/${lib.toLower cfg.rootPartitionUuid}";
      label = "cloudimg-rootfs";
      fsType = "ext4";
      autoResize = true;
    };

    boot = {
      loader.grub.device = "/dev/vda";

      initrd.kernelModules = modules;
      kernelModules = modules;
      kernelParams = [
        # Enable support for the serial console
        "console=tty0"
        "console=ttyS0,115200" # c-p from live system
        "consoleblank=0" # c-p from live system
        "nofb" # c-p from live system
        "clocksource_failover=acpi_pm" # c-p from live system
        # "vga=0x0300"
        "nomodeset"
        "gfxpayload=text"
        "vga=keep"
      ];

      growPartition = true;
    };

    environment.etc.securetty = {
      text = "ttyS0";
      mode = "0644";
    };

    systemd.services."serial-getty@ttyS0".enable = true;

    services.openssh.enable = true;
    services.cloud-init = lib.mkDefault {
      enable = true;
      settings = {
        # network.config = "disabled";
      };
    };

    systemd.network.enable = true;
    networking.useNetworkd = true;
    networking.useDHCP = true;
    networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

    services.qemuGuest.enable = true;

    system.build.selectelCloudImage = import (pkgs.path + "/nixos/lib/make-disk-image.nix") {
      inherit lib config pkgs;
      additionalSpace = "128M";
      format = "qcow2";
      partitionTableType = "legacy+gpt";
      label = "cloudimg-rootfs";
      rootGPUID = cfg.rootPartitionUuid;
    };
  };
}
