{ lib, config, secrets, pkgs, ... }:
{
  options.rubikoid.services.immich =
    let
      types = lib.types;
    in
    {
      version = lib.mkOption {
        type = types.str;
        default = "v1.108.0-ig303"; # "v1.95.1-ig252"; # "v1.94.1-ig247"; # "v1.90.0-ig222"; # "v1.89.0-ig220";
      };

      port = lib.mkOption {
        type = types.port;
        default = 2283;
      };

      caddyName = lib.mkOption {
        type = types.str;
        default = "immich";
      };
    };

  config =
    let
      cfg = config.rubikoid.services.immich;
      env = { };
    in
    {
      systemd.services.docker-network-immich = pkgs.my-lib.mkDockerNet config "immich";

      virtualisation.oci-containers.containers = {
        immich = {
          autoStart = true;
          image = "ghcr.io/imagegenius/immich:${cfg.version}";
          volumes = [
            "/data/home/immich/config:/config"
            "/data/home/immich/photos:/photos"
            "/data/home/immich/config/machine-learning:/config/machine-learning"
          ];
          # ports = [ "127.0.0.1:${toString cfg.port}:8080" ];
          ports = [ "0.0.0.0:${toString cfg.port}:8080" ];
          environment = {
            PUID = "1000";
            PGID = "1000";
            TZ = "Europe/Moscow"; # Change this to your timezone
            DB_HOSTNAME = "immich-postgres14";
            DB_USERNAME = "postgres";
            DB_PASSWORD = "postgres";
            DB_DATABASE_NAME = "immich";
            REDIS_HOSTNAME = "immich-redis";

            IMMICH_BUILD_DATA = "/app/immich/server";
          };
          extraOptions = [ "--network=immich-net" "--gpus=all" ];
        };

        immich-redis = {
          autoStart = true;
          image = "redis";
          # ports = [ "127.0.0.1:6379:6379" ];
          extraOptions = [ "--network=immich-net" ];
        };

        immich-postgres14 = {
          autoStart = true;
          image = "tensorchord/pgvecto-rs:pg14-v0.2.0";
          # ports = [ "5432:5432" ];
          volumes = [
            "pgdata:/var/lib/postgresql/data"
          ];
          environment = {
            POSTGRES_USER = "postgres";
            POSTGRES_PASSWORD = "postgres";
            POSTGRES_DB = "immich";
          };
          extraOptions = [ "--network=immich-net" ];
        };
      };

      networking.firewall.allowedTCPPorts = [ cfg.port ];

      services.caddy.virtualHosts."${cfg.caddyName}.${secrets.dns.private}" = {
        extraConfig = ''
          reverse_proxy http://127.0.0.1:${toString cfg.port}
          import stepssl_acme
        '';
      };
    };
}
