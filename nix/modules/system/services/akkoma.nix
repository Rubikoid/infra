{ lib, config, secrets, pkgs, ... }:
let
  types = lib.types;
  cfg = config.rubikoid.services.akkoma;
  httpCfg = config.rubikoid.http.services.akkoma;

  public_url = "${cfg.caddyName}.${secrets.dns.public}";

  mkRaw = (pkgs.formats.elixirConf { }).lib.mkRaw;
  mkMap = (pkgs.formats.elixirConf { }).lib.mkMap;
in
{
  options.rubikoid.services.akkoma = {
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

  config = {
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

    rubikoid.http.services.akkoma = {
      name = cfg.caddyName;
      hostOnHost = cfg.host;
      inherit (cfg) port;

      caddyConfig = ''
        encode gzip
      
        @forward-from-upstream header X-Forwarded-Host "${public_url}"

        reverse_proxy @forward-from-upstream http://127.0.0.1:${toString httpCfg.port} {
          header_up Host "${public_url}"
        }

        reverse_proxy http://127.0.0.1:${toString httpCfg.port}
        import stepssl_acme
      '';
    };
  };
}
