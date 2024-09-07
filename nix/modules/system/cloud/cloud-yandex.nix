# Profile for virtual machines on Yandex Cloud, intended for disk
# images.
#
# https://cloud.yandex.com/ru/docs/compute/operations/image-create/custom-image
#
# TODO(tazjin): Upstream to nixpkgs once it works well.
# https://code.tvl.fyi/tree/corp/ops/modules/yandex-cloud.nix?id=6daf91c9cd52b729483aca6e1eaafc50fd796e7f

{ config, lib, pkgs, modulesPath, ... }:

let
  cfg = config.virtualisation.yandexCloud;

  # Kernel modules required for interacting with the hypervisor. These
  # must be available during stage 1 boot and during normal operation,
  # as disks and network do not work without them.
  modules = [
    "virtio-net"
    "virtio-blk"
    "virtio-pci"
    "virtiofs"
  ];
in
{
  imports = [
    "${modulesPath}/profiles/headless.nix"
  ];

  options = {
    virtualisation.yandexCloud.rootPartitionUuid = with lib; mkOption {
      type = types.str;
      default = "C55A5EE2-E5FA-485C-B3AE-CC928429AB6B";

      description = ''
        UUID to use for the root partition of the disk image. Yandex
        Cloud requires that root partitions are mounted by UUID.

        Most users do not need to set this to a non-default value.
      '';
    };
  };

  config = {
    fileSystems."/" = {
      device = "/dev/disk/by-uuid/${lib.toLower cfg.rootPartitionUuid}";
      fsType = "ext4";
      autoResize = true;
    };

    boot = {
      loader.grub.device = "/dev/vda";

      initrd.kernelModules = modules;
      kernelModules = modules;
      kernelParams = [
        # Enable support for the serial console
        "console=ttyS0"
      ];

      growPartition = true;
    };

    environment.etc.securetty = {
      text = "ttyS0";
      mode = "0644";
    };

    systemd.services."serial-getty@ttyS0".enable = true;

    services.openssh.enable = true;
    services.cloud-init.enable = true;

    system.build.yandexCloudImage = import (pkgs.path + "/nixos/lib/make-disk-image.nix") {
      inherit lib config pkgs;
      additionalSpace = "128M";
      format = "qcow2";
      partitionTableType = "legacy+gpt";
      rootGPUID = cfg.rootPartitionUuid;
    };
  };
}
