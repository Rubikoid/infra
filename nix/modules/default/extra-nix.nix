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
      registry =
        let
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
          r.to = rubikoid;
          rubikoid.to = rubikoid;
          base.flake = inputs.base;
        };

      settings = {
        # чтобы работало, надо либо чтобы юзер был в trusted-users, либо репа в trusted-substituters
        # я добавляю и то и туда, чтобы работало гарантированно.
        substituters = [
          "https://${secrets.harmonia.addr}"
        ];
        trusted-substituters = [
          "https://${secrets.harmonia.addr}"
        ];
        trusted-public-keys = [
          "${secrets.harmonia.addr}:${secrets.harmonia.key}"
        ];
      };
    };
  };
}
