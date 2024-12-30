{
  pkgs,
  lib,
  config,
  inputs,
  secrets,
  ...
}:

{
  options.rubikoid.nix = { };
  config = {
    nix = {
      package = pkgs.nix;

      registry =
        let
          nixpkgs = inputs.nixpkgs;
          rubikoid =
            let
              flake = inputs.self;
            in
            {
              type = "path";
              path = flake.outPath;
              dir = "nix";
            }
            // lib.filterAttrs (
              n: _: n == "lastModified" || n == "rev" || n == "revCount" || n == "narHash"
            ) flake;
        in
        {
          n.flake = nixpkgs;
          nixpkgs.flake = nixpkgs;
          r.to = rubikoid;
          rubikoid.to = rubikoid;
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
          # "repl-flake"
        ];

        flake-registry = lib.mkForce ""; # бе-бе-бе, я сам себе registry

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
  };
}
