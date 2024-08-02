{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  cfg = config.rubikoid.services.overleaf;
in
{
  options.rubikoid.services.overleaf = {
    version = lib.mkOption {
      type = types.str;
      default = "3.5.13-full";
    };

    host = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = types.port;
      default = 8732;
    };

    caddyName = lib.mkOption {
      type = types.str;
      default = "tex";
    };

    dataFolder = lib.mkOption {
      type = types.path;
      default = "/backup-drive/data/overleaf";
    };
  };

  config = {
    # services.redis.servers.overleaf = {
    #   enable = true;
    #   bind = "0.0.0.0";
    #   port = 12341;
    # };

    # services.ferretdb = {
    #   enable = true;
    #   settings = {
    #     FERRETDB_LISTEN_ADDR = "0.0.0.0:27017";
    #   };
    # };

    systemd.services.docker-network-overleaf = pkgs.my-lib.mkDockerNet config "overleaf";

    virtualisation.oci-containers.containers = {
      overleaf-redis = {
        image = "redis";

        volumes = [
          "${cfg.dataFolder}-redis:/data"
        ];

        extraOptions = [ "--network=overleaf-net" ];
      };

      overleaf-db = {
        # image = "ghcr.io/ferretdb/ferretdb";
        image = "mongo:4.4";

        environment = {
          FERRETDB_HANDLER = "sqlite";
        };

        volumes = [
          # "${cfg.dataFolder}-db:/state"
          "${cfg.dataFolder}-db:/data/db"
        ];

        extraOptions = [ "--network=overleaf-net" ];
      };

      overleaf = {
        image = "sharelatex:${cfg.version}";

        environment =
          let
            redis = "overleaf-redis";
          in
          {
            SHARELATEX_APP_NAME = "Overleaf CE (Rubikoid)";

            ENABLED_LINKED_FILE_TYPES = "project_file,project_output_file";

            ENABLE_CONVERSIONS = "true";

            SHARELATEX_MONGO_URL = "mongodb://overleaf-db/sharelatex";
            SHARELATEX_REDIS_HOST = redis;
            REDIS_HOST = redis;
          };

        ports = [
          "${cfg.host}:${toString cfg.port}:80"
        ];

        volumes = [
          "${cfg.dataFolder}:/var/lib/sharelatex"
        ];

        extraOptions = [ "--network=overleaf-net" ];
      };
    };

    rubikoid.http.services.overleaf = {
      name = cfg.caddyName;
      hostOnHost = cfg.host;
      inherit (cfg) port;
    };
  };
}
