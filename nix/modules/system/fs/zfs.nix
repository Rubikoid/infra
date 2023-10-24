{ lib, ... }:

{
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = lib.mkDefault false;
  services.zfs.autoScrub.enable = lib.mkDefault true;
}
