{ lib, config, secrets, pkgs, ... }:
{
  options.rubikoid.services.memos =
    let
      types = lib.types;
    in
    {
      version = lib.mkOption {
        type = types.str;
        default = "0.21.0";
      };

      host = lib.mkOption {
        type = types.str;
        default = "127.0.0.1";
      };

      port = lib.mkOption {
        type = types.port;
        default = 5230;
      };

      dataFolder = lib.mkOption {
        type = types.str;
        default = "/backup-drive/data/memos";
      };

      caddyName = lib.mkOption {
        type = types.str;
        default = "memos";
      };
    };

  config =
    let
      cfg = config.rubikoid.services.memos;
    in
    {
      virtualisation.oci-containers.containers = {
        memos = {
          image = "ghcr.io/usememos/memos:${cfg.version}";

          ports = [
            "${cfg.host}:${toString cfg.port}:5230"
          ];

          volumes = [
            "${cfg.dataFolder}:/var/opt/memos"
          ];
        };
      };

      rubikoid.http.services.memos = {
        name = cfg.caddyName;
        hostOnHost = cfg.host;
        inherit (cfg) port;
      };
    };
}
