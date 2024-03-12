{ config, lib, pkgs, ... }:
{
  imports = [
    ./rmrf.nix
  ];

  services.cloud-init.network.enable = true;
  proxmox = {
    qemuConf = {
      cores = 4;
      memory = 2048;
      agent = true;
      virtio0 = "local:vm-9999-disk-0";
      name = "nixos-test";
      bios = "ovmf";
    };
  };

  users = {
    mutableUsers = false;
    users.root = {
      hashedPassword = "$y$j9T$PKJs/5MFEJeQAVIfPk1Fr.$RNQxjT8BoXlUOSZeCeMO3Q60m7APG9HR/lCtwy/QXf9";
    };
  };
}
