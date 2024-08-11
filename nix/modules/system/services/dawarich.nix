{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  cfg = config.rubikoid.services.dawarich;
  sname = "dawarich";
  hostname = config.rubikoid.http.services.dawarich.fqdn;
in
{
  options.rubikoid.services.dawarich = {
    version = lib.mkOption {
      type = types.str;
      default = "0.9.4";
    };

    host = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = types.port;
      default = 11578;
    };

    caddyName = lib.mkOption {
      type = types.str;
      default = "dawarich";
    };

    sidekiqWorkers = lib.mkOption {
      type = types.int;
      default = 10;
    };
  };

  config = {
    systemd.services.docker-network-dawarich = pkgs.my-lib.mkDockerNet config "${sname}";

    rubikoid.services.dawarich = {
      sidekiqWorkers = 50;
    };

    virtualisation.oci-containers.containers =
      let
        opts = {
          image = "freikin/dawarich:${cfg.version}";

          autoStart = true;

          extraOptions = [
            "--network=${sname}-net"
            "--tty"
            # "--interactive"
          ];

          volumes = [
            "${sname}_gem_cache:/usr/local/bundle/gems"
            "${sname}_public:/var/app/public"
          ];
        };

        env = {
          RAILS_ENV = "development";
          REDIS_URL = "redis://dawarich-redis:6379/0";

          DATABASE_HOST = "dawarich-db";
          DATABASE_USERNAME = "postgres";
          DATABASE_PASSWORD = "password";
          DATABASE_NAME = "dawarich_development";

          APPLICATION_HOST = "localhost,${hostname}";
          APPLICATION_HOSTS = "localhost,${hostname}";
          APPLICATION_PROTOCOL = "http";
        };
      in
      {
        dawarich-app = opts // {
          # entrypoint = "dev-entrypoint.sh";
          cmd = [ "bin/dev" ];

          ports = [ "127.0.0.1:${toString cfg.port}:3000" ];

          environment = env // {
            MIN_MINUTES_SPENT_IN_CITY = "60";
            TIME_ZONE = "Europe/Moscow";
          };

          dependsOn = [ "${sname}-db" "${sname}-redis" ];
        };

        dawarich-sidekiq = opts // {
          autoStart = false;

          entrypoint = "dev-entrypoint.sh";
          cmd = [ "sidekiq" ];

          environment = env // {
            BACKGROUND_PROCESSING_CONCURRENCY = toString cfg.sidekiqWorkers;
          };

          dependsOn = [ "${sname}-db" "${sname}-redis" "${sname}-app" ];
        };

        dawarich-redis = {
          image = "redis:7.0-alpine";

          volumes = [ "${sname}_shared_data:/var/shared/redis" ];

          extraOptions = [ "--network=${sname}-net" ];
        };

        dawarich-db = {
          image = "postgres:14.2-alpine";

          environment = {
            POSTGRES_USER = env.DATABASE_USERNAME;
            POSTGRES_PASSWORD = env.DATABASE_PASSWORD;
          };

          volumes = [
            "${sname}_db_data:/var/lib/postgresql/data"
            "${sname}_shared_data:/var/shared/redis"
          ];

          extraOptions = [ "--network=${sname}-net" ];
        };
      };

    rubikoid.http.services.dawarich = {
      name = cfg.caddyName;
      hostOnHost = cfg.host;
      inherit (cfg) port;
    };
  };
}
