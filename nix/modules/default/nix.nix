{ pkgs, lib, config, inputs, secrets, ... }:

{
  nix = {
    package = pkgs.nix;

    registry = {
      nixpkgs.flake = inputs.nixpkgs;
      n.flake = inputs.nixpkgs;

      # {
      #   to = { type = "github"; owner = "NixOS"; repo = "nixpkgs"; rev = inputs.nixpkgs.rev; };
      #   exact = false;
      # };
    };

    # linking hardlinks inside store
    # good thing
    optimise.automatic = true;

    gc = {
      automatic = true;
      dates = lib.mkIf (!config.isDarwin) "weekly";
      options = "--delete-older-than 7d";
    };

    # nix command, flakes
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "repl-flake"
      ];

      # чтобы работало, надо либо чтобы юзер в trusted-users, либо репа в trusted-substituters
      # я добавляю и то и туда, чтобы работало гарантированно. 
      substituters = [
        "https://${secrets.harmonia.addr}"
        # "https://cache.nixos.org" # а это больше не добавляю, потому что оно дополняет, а не заменяет, как выяснилось
      ];
      trusted-substituters = [
        "https://${secrets.harmonia.addr}"
      ];
      trusted-public-keys = [
        "${secrets.harmonia.addr}:${secrets.harmonia.key}"
        # "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
  };
}
