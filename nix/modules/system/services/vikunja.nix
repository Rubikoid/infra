{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  cfg = config.rubikoid.services.vikunja;
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

      frontendHostname = config.rubikoid.http.services.vikunja.fqdn;
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

    rubikoid.http.services.vikunja = {
      name = cfg.caddyName;
      hostOnHost = cfg.host;
      inherit (cfg) port;
    };
  };
}
