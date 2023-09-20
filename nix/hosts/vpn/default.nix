{ inputs, lib, ... }:

{
  imports = with inputs.self.systemModules; [
    ./hardware-configuration.nix
    yggdrasil
  ];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = false;

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOXNeouqZX2g3lYGgI+R9kGOBGPhV+cOvXOHPxKRygKl rubikoid@rubikoid.ru''
  ];

  services.yggdrasil = {
    settings = {
      Listen = [
        "tls://0.0.0.0:51342"
      ];
      MulticastInterfaces = lib.mkForce [ ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
