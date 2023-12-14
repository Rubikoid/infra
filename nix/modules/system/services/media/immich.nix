{ lib, config, secrets, pkgs, ... }:
{
  options.rubikoid.services.immich =
    let
      types = lib.types;
    in
    {
      version = lib.mkOption {
        type = types.str;
        default = "v1.90.0-ig222"; # "v1.89.0-ig220";
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
      systemd.services.init-filerun-network-and-files = {
        description = "Create the network bridge for Immich.";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig.Type = "oneshot";
        script =
          let dockercli = "${config.virtualisation.docker.package}/bin/docker";
          in
          ''
            # immich-net network
            check=$(${dockercli} network ls | grep "immich-net" || true)
            if [ -z "$check" ]; then
              ${dockercli} network create immich-net
            else
              echo "immich-net already exists in docker"
            fi
          '';
      };

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
            DB_HOSTNAME = "postgres14";
            DB_USERNAME = "postgres";
            DB_PASSWORD = "postgres";
            DB_DATABASE_NAME = "immich";
            REDIS_HOSTNAME = "redis";
          };
          extraOptions = [ "--network=immich-net" "--gpus=all" ];
        };

        redis = {
          autoStart = true;
          image = "redis";
          # ports = [ "127.0.0.1:6379:6379" ];
          extraOptions = [ "--network=immich-net" ];
        };

        postgres14 = {
          autoStart = true;
          image = "postgres:14";
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
