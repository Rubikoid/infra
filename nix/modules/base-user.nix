{ inputs, pkgs, lib, config, secrets, device, mode, ... }:

{
  # programs.home-manager.enable = true; # idk why i need that
  home =
    let
      baseHomePath = if lib.hasPrefix "Darwin" mode then "/Users" else "/home";
    in
    {
      username = config.user;
      homeDirectory = "${baseHomePath}/${config.user}";
      stateVersion = "24.05";
    };
}
