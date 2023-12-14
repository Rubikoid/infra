{ lib, config, secrets, pkgs, ... }:
{
  options.rubikoid.services.jellyfin =
    let
      types = lib.types;
    in
    {
      caddyName = lib.mkOption {
        type = types.str;
        default = "jellyfin";
      };
    };

  config =
    let
      cfg = config.rubikoid.services.jellyfin;
    in
    {
      services.jellyfin = {
        enable = true;
        openFirewall = false;
      };
      # rubikoid.services.media.mediaWriters = [ config.services.jellyfin.user ];

      services.caddy.virtualHosts."${cfg.caddyName}.${secrets.dns.private}" = {
        extraConfig = ''
          reverse_proxy http://127.0.0.1:8096
          import stepssl_acme
        '';
      };
    };
}
