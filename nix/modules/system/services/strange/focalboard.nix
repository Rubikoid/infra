{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  cfg = config.rubikoid.services.focalboard;
  accessUrl = "${cfg.caddyName}.${secrets.dns.private}";
  internalUrl = "${cfg.caddyName}.${secrets.dns.private}";
in
{
  options.rubikoid.services.focalboard = {
    version = lib.mkOption {
      type = types.str;
      default = "ad6c9dd59fdf9a18f2ef9666093b1809aaf7a38c04c524a25e81605f204a891e";
      # edge at 08.01.2023
    };

    host = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = types.port;
      default = 9231;
    };

    caddyName = lib.mkOption {
      type = types.str;
      default = "focalboard";
    };

    dataFolder = lib.mkOption {
      type = types.path;
      default = "/backup-drive/data/focalboard";
    };
  };

  config =
    let
      jsonedCfg = pkgs.writeText "config.json" (builtins.toJSON {
        serverRoot = "https://${internalUrl}";
        port = 8000;
        dbtype = "sqlite3";
        dbconfig = "./data/focalboard.db";
        postgres_dbconfig = "dbname=focalboard sslmode=disable";
        useSSL = false;
        webpath = "./pack";
        filespath = "./data/files";
        telemetry = false;
        session_expire_time = 2592000;
        session_refresh_time = 18000;
        localOnly = false;
        enableLocalMode = true;
        localModeSocketLocation = "/var/tmp/focalboard_local.socket";
        prometheus_address = "";
      });
    in
    {
      virtualisation.oci-containers.containers = {
        focalboard = {
          image = "mattermost/focalboard@sha256:${cfg.version}";

          ports = [
            "${cfg.host}:${toString cfg.port}:8000"
          ];

          volumes = [
            "${cfg.dataFolder}:/opt/focalboard/data"
            "${jsonedCfg}:/opt/focalboard/config.json:ro"
          ];
        };
      };

      services.caddy.virtualHosts.${internalUrl} = {
        extraConfig = ''
          reverse_proxy http://127.0.0.1:${toString cfg.port}
          import stepssl_acme
        '';
      };
    };
}
