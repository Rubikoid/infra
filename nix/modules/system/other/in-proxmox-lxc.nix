{ modulesPath, ... }:

{
  imports = [
    "${toString modulesPath}/virtualisation/proxmox-lxc.nix"
  ];
}
