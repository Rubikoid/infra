{ pkgs, ... }:

{
  boot = {
    extraModulePackages = with pkgs.linuxPackages; [ it87 ];

    kernelModules = [ "drivetemp" "coretemp" "it87" ];

    extraModprobeConfig = ''
      options it87 ignore_resource_conflict=1 force_id=0x8689
    '';
  };
}
