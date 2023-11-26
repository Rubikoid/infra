{ lib, config, secrets, pkgs, ... }:
{
  options.rubikoid.services.actual =
    let
      types = lib.types;
    in
    {
      version = lib.mkOption {
        type = types.str;
        default = "23.11.0";
      };

      host = lib.mkOption {
        type = types.str;
        default = "127.0.0.1";
      };

      port = lib.mkOption {
        type = types.port;
        default = 5006;
      };

      dataFolder = lib.mkOption {
        type = types.str;
        default = "/backup-drive/data/actual_data";
      };

      caddyName = lib.mkOption {
        type = types.str;
        default = "actual";
      };
    };

  config =
    let
      cfg = config.rubikoid.services.actual;
    in
    {
      virtualisation.oci-containers.containers = {
        actual = {
          image = "actualbudget/actual-server:${cfg.version}";

          ports = [
            "${cfg.host}:${toString cfg.port}:5006"
          ];

          volumes = [
            "${cfg.dataFolder}:/data"
          ];
        };
      };

      services.caddy.virtualHosts."${cfg.caddyName}.${secrets.dns.private}" = {
        extraConfig = ''
          reverse_proxy http://127.0.0.1:${toString cfg.port}
          import stepssl_acme
        '';
      };
    };
}
