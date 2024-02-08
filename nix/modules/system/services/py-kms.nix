{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  cfg = config.rubikoid.services.py-kms;
in
{
  options.rubikoid.services.py-kms = {
    version = lib.mkOption {
      type = types.str;
      default = "95a73f03dfea0f9f4a234e5fa529a68614257108fd3b15110d6b80ab737e377e";
    };

    host = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = types.port;
      default = 8712;
    };

    caddyName = lib.mkOption {
      type = types.str;
      default = "py-kms";
    };

    dataFolder = lib.mkOption {
      type = types.path;
      default = "/backup-drive/data/py-kms";
    };
  };

  config = {
    virtualisation.oci-containers.containers = {
      py-kms = {
        image = "ghcr.io/py-kms-organization/py-kms@sha256:${cfg.version}";

        ports = [
          "1688:1688"
          "${cfg.host}:${toString cfg.port}:8080"
        ];

        volumes = [
          "${cfg.dataFolder}:/home/py-kms/db"
          "/etc/localtime:/etc/localtime:ro"
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
