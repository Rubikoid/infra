{ inputs, lib, ... }:

{
  imports = with inputs.self.nixosModules; with inputs.self.nixosProfiles; [
    ./hardware-configuration.nix
  ];

  networking.wireless = {
    networks = {
      "@home_uuid@" = { psk = "@home_psk@"; };
      "@bk252_uuid@" = { psk = "@bk252_psk@"; };
      "@iphone_uuid@" = { psk = "@iphone_psk@"; };
      "@pt_uuid@" = { psk = "@pt_psk@"; };
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
