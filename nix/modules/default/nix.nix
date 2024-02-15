{ pkgs, inputs, secrets, ... }:

{
  nix = {
    package = pkgs.nix;

    registry = {
      n.flake = inputs.nixpkgs;
      # {
      #   to = { type = "github"; owner = "NixOS"; repo = "nixpkgs"; rev = inputs.nixpkgs.rev; };
      #   exact = false;
      # };
    };

    # idk wtf is it, but sounds good;
    optimise.automatic = true;

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    # nix command, flakes
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "repl-flake"
      ];
      substituters = [
        "https://${secrets.harmonia.addr}"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "${secrets.harmonia.addr}:${secrets.harmonia.key}"
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
  };
}
