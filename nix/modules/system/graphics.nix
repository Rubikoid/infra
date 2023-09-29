{ inputs, pkgs, ... }:

{
  imports = [
    inputs.hyprland.nixosModules.default
  ];

  nix = {
    settings = {
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
  };

  programs.hyprland = {
    # Enable hyprland
    enable = true;

    # enable xwayland, but without hidpi
    xwayland.enable = true;

    # patching wlroots for better Nvidia support (don't need on intel only)
    enableNvidiaPatches = false;
  };

  security.pam.services.swaylock = { };
}
