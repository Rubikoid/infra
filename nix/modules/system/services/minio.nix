{ lib, config, secrets, pkgs, ... }:
{
  options.rubikoid.services.minio =
    let
      types = lib.types;
    in
    {
      keys = {
        access = lib.mkOption {
          type = types.str;
          default = secrets.minio-keys.access;
        };

        secret = lib.mkOption {
          type = types.str;
          default = secrets.minio-keys.secret;
        };
      };

      access = {
        host = lib.mkOption {
          type = types.str;
          default = "127.0.0.1";
        };

        port = lib.mkOption {
          type = types.port;
          default = 9000;
        };
      };

      console = {
        host = lib.mkOption {
          type = types.str;
          default = "127.0.0.1";
        };

        port = lib.mkOption {
          type = types.port;
          default = 9001;
        };
      };

      region = lib.mkOption {
        type = types.str;
        default = "ru-west-1";
      };

      dataFolders = lib.mkOption {
        type = types.listOf types.str;
        default = [
          "/backup-drive/data/minio"
        ];
      };

      caddyName = lib.mkOption {
        type = types.str;
        default = "minio-console";
      };
    };

  config =
    let
      cfg = config.rubikoid.services.minio;
    in
    {
      services.minio = {
        enable = true;

        accessKey = cfg.keys.access;
        secretKey = cfg.keys.secret;

        region = cfg.region;

        listenAddress = "${cfg.access.host}:${toString cfg.access.port}";
        consoleAddress = "${cfg.console.host}:${toString cfg.console.port}";

        dataDir = cfg.dataFolders;
      };

      rubikoid.http.services.minio = {
        name = cfg.caddyName;
        hostOnHost = cfg.console.host;
        inherit (cfg.console) port;
      };
    };
}
