{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  cfg = config.rubikoid.services.tubearchive;
in
{
  options.rubikoid.services.tubearchive = {
    version = lib.mkOption {
      type = types.str;
      default = "v0.4.10";
    };

    host = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = types.port;
      default = 11032;
    };

    caddyName = lib.mkOption {
      type = types.str;
      default = "yt";
    };

    dataFolder = lib.mkOption {
      type = types.str;
      default = "/data/docker-data/tubearchivist";
    };

  };

  config = {
    systemd.services.docker-network-tubearchive = lib.r.mkDockerNet config "tubearchive";

    virtualisation.oci-containers.containers =
      let
        ES_PW = "fill me";
        NETWORK = "--network=tubearchive-net";
      in
      {
        tubearchive = {
          image = "bbilly1/tubearchivist:${cfg.version}";

          environment = {
            ES_URL = "http://tubearchive-es:9200";
            ELASTIC_PASSWORD = ES_PW;

            REDIS_HOST = "tubearchive-redis";

            TA_HOST = "https://${config.rubikoid.http.services.tubearchive.fqdn}";
            TA_USERNAME = "rubikoid";
            TA_PASSWORD = "test";

            TZ = "Europe/Moscow";          };

          ports = [
            "${cfg.host}:${toString cfg.port}:8000"
          ];

          volumes = [
            "${cfg.dataFolder}/media:/youtube"
            "${cfg.dataFolder}/cache:/cache"
          ];

          dependsOn = [ "tubearchive-redis" "tubearchive-es" ];
          extraOptions = [ NETWORK ];
        };

        tubearchive-redis = {
          image = "redis/redis-stack-server:7.4.0-v0";

          volumes = [
            "${cfg.dataFolder}/redis:/data"
          ];

          dependsOn = [ "tubearchive-es" ];
          extraOptions = [ NETWORK ];
        };

        tubearchive-es = {
          image = "bbilly1/tubearchivist-es:8.14.3";

          volumes = [
            "${cfg.dataFolder}/es:/usr/share/elasticsearch/data"
          ];

          environment = {
            ELASTIC_PASSWORD = ES_PW;
            ES_JAVA_OPTS = "-Xms1g -Xmx1g";
            "xpack.security.enabled" = "true";
            "discovery.type" = "single-node";
            "path.repo" = "/usr/share/elasticsearch/data/snapshot";
          };

          extraOptions = [ NETWORK ];
        };
      };

    rubikoid.http.services.tubearchive = {
      name = cfg.caddyName;
      hostOnHost = cfg.host;
      inherit (cfg) port;
    };
  };
}
