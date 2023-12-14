{ lib, config, secrets, pkgs, ... }:
{
  options.rubikoid.services.akkoma =
    let
      types = lib.types;
    in
    {
      host = lib.mkOption {
        type = types.str;
        default = "127.0.0.1";
      };

      port = lib.mkOption {
        type = types.port;
        default = 4000;
      };

      caddyName = lib.mkOption {
        type = types.str;
        default = "fedi";
      };
    };

  config =
    let
      cfg = config.rubikoid.services.akkoma;

      public_url = "${cfg.caddyName}.${secrets.dns.public}";
      private_url = "${cfg.caddyName}.${secrets.dns.private}";

      mkRaw = (pkgs.formats.elixirConf { }).lib.mkRaw;
      mkMap = (pkgs.formats.elixirConf { }).lib.mkMap;
    in
    {
      services.akkoma = {
        enable = true;

        config = {
          # ":logger".":ex_syslogger" = {
          #   level = ":debug";
          # };

          ":pleroma" = {
            ":instance" = {
              name = "Rubikoid's akkoma";
              email = "akkoma+admin@rubikoid.ru";
              description = "Just small akkoma inst";
              registration_open = false;
              invites_enabled = true;

              federating = true;

              allow_relay = true;
              public = true;
            };

            "Pleroma.Web.Endpoint" = {
              http = {
                ip = cfg.host;
                port = cfg.port;
              };
              url.host = public_url;
            };

            ":mrf".policies = map mkRaw [
              "Pleroma.Web.ActivityPub.MRF.SimplePolicy"
            ];

            ":mrf_simple" = { };
          };
        };
      };
      
      # reverse_proxy unix/${cfg.http.ip}
      services.caddy.virtualHosts.${private_url} = {
        extraConfig = ''
          encode gzip
      
          @forward-from-upstream header X-Forwarded-Host "${public_url}"

          reverse_proxy @forward-from-upstream http://127.0.0.1:${toString cfg.port} {
            header_up Host "${public_url}"
          }

          reverse_proxy http://127.0.0.1:${toString cfg.port}
      
          import stepssl_acme
        '';
      };
    };
}
