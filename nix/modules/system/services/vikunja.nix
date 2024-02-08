{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  cfg = config.rubikoid.services.vikunja;
  privateName = "${cfg.caddyName}.${secrets.dns.private}";
in
{
  options.rubikoid.services.vikunja = {
    host = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = types.port;
      default = 9831;
    };

    caddyName = lib.mkOption {
      type = types.str;
      default = "todo";
    };

    dataFolder = lib.mkOption {
      type = types.path;
      default = "/backup-drive/data/vikunja";
    };
  };

  config = {
    services.vikunja = {
      enable = true;

      port = cfg.port;

      frontendHostname = privateName;
      frontendScheme = "https";

      # database = {
      #   path = "${cfg.dataFolder}/vikunja.db";
      # };

      settings = {
        service = {
          timezone = "Europe/Moscow";
        };
      };
    };
    services.caddy.virtualHosts.${privateName} = {
      extraConfig = ''
        root * ${config.services.vikunja.package-frontend.outPath}
        
        handle /api/* {
          reverse_proxy http://127.0.0.1:${toString cfg.port}
        }
        
        handle /.well-known/* {
          reverse_proxy http://127.0.0.1:${toString cfg.port}
        }
        
        handle /dav/* {
          reverse_proxy http://127.0.0.1:${toString cfg.port}
        }
        
        handle {
          try_files {path} {path}/ /
          file_server
        }
        
        import stepssl_acme
      '';
    };
  };
}
