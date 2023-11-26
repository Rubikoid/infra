# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ "nvme" ];

  boot.loader.grub.device = "/dev/sda";

  fileSystems."/" =
    {
      device = "/dev/mapper/vg17422-root";
      fsType = "ext4";
    };

  swapDevices = [
    { device = "/dev/dm-0"; }
  ];
}
