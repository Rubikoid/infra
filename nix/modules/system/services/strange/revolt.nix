{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  sname = "revolt";
  cfg = config.rubikoid.services.${sname};

  revoltBasePath = "ghcr.io/revoltchat";
  fqdn = "${cfg.caddyName}.${secrets.dns.public}";

  env =
    let
      httpFQDN = "https://${fqdn}";
    in
    {
      MONGODB = "mongodb://127.0.0.1:27017";
      REDIS_URI = "redis://127.0.0.1/";

      HOSTNAME = httpFQDN;
      REVOLT_APP_URL = httpFQDN;

      REVOLT_PUBLIC_URL = "${httpFQDN}/api";
      VITE_API_URL = "${httpFQDN}/api";

      REVOLT_EXTERNAL_WS_URL = "wss://${fqdn}/ws";

      AUTUMN_PUBLIC_URL = "";
      JANUARY_PUBLIC_URL = "";

      REVOLT_UNSAFE_NO_CAPTCHA = "1";
      REVOLT_UNSAFE_NO_EMAIL = "1";

      REVOLT_INVITE_ONLY = "1";
      REVOLT_MAX_GROUP_SIZE = "64";

      REVOLT_VAPID_PRIVATE_KEY = "fill me";
      REVOLT_VAPID_PUBLIC_KEY = "fill me";
    };

  tomlSettings = {
    database = {
      mongodb = env.MONGODB;
      redis = env.REDIS_URI;
    };

    hosts = {
      app = env.REVOLT_APP_URL;
      api = env.REVOLT_PUBLIC_URL;
      events = env.REVOLT_EXTERNAL_WS_URL;
    };

    api = {
      registration = {
        invite_only = true;
      };
      vapid = {
        private_key = env.REVOLT_VAPID_PRIVATE_KEY;
        public_key = env.REVOLT_VAPID_PUBLIC_KEY;
      };
    };

    files.limit.min_file_size = 999999;
  };

  tomlFile = (pkgs.formats.toml { }).generate "Revolt.toml" tomlSettings;

  revoltDataPath = "/data/revolt";
  revoltConfig = "${tomlFile}:/Revolt.toml:ro";

  networkOption = "--network=host";
in
{
  options.rubikoid.services.${sname} = {
    version = lib.mkOption {
      type = types.str;
      default = "20240929-1";
    };

    host = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
    };

    caddyName = lib.mkOption {
      type = types.str;
      default = sname;
    };
  };

  config = {
    # systemd.services."docker-network-${sname}" = lib.r.mkDockerNet config "${sname}";

    # services.ferretdb = {
    #   enable = true;
    #   settings = {
    #     FERRETDB_LISTEN_ADDR = "127.0.0.1:27017";
    #     FERRETDB_TELEMETRY = "disabled";
    #   };
    # };

    services.redis.servers.${sname} = {
      enable = true;
      port = 6379;
    };

    virtualisation.oci-containers.containers = {
      "${sname}-mongodb" = {
        image = "mongo:4.4.29";

        # ports = [
        #   "${cfg.host}:${toString cfg.port}:5000"
        # ];

        volumes = [
          "${revoltDataPath}/mongo-data:/data/db"
        ];

        extraOptions = [
          networkOption
        ];
      };

      "${sname}-server" = {
        image = "${revoltBasePath}/server:${cfg.version}";

        # ports = [
        #   "${cfg.host}:${toString cfg.port}:5000"
        # ];

        environment = env;

        volumes = [
          revoltConfig
        ];

        extraOptions = [
          networkOption
        ];
      };

      "${sname}-events" = {
        image = "${revoltBasePath}/bonfire:${cfg.version}";

        # ports = [
        #   "${cfg.host}:${toString cfg.port}:port"
        # ];

        environment = env;

        volumes = [
          revoltConfig
        ];

        extraOptions = [
          networkOption
        ];
      };

      "${sname}-web" = {
        image = "${revoltBasePath}/client:master";

        # ports = [
        #   "${cfg.host}:${toString cfg.port}:port"
        # ];

        environment = env;

        volumes = [ ];

        extraOptions = [
          networkOption
        ];
      };

      # "${sname}-autumn" = {
      #   image = "${revoltBasePath}/autumn:1.1.11";

      #   ports = [
      #     "${cfg.host}:${toString cfg.port}:port"
      #   ];

      #   volumes = [ ];
      # };

      # "${sname}-january" = {
      #   image = "${revoltBasePath}/january:0.3.5";

      #   ports = [
      #     "${cfg.host}:${toString cfg.port}:port"
      #   ];

      #   volumes = [ ];
      # };
    };

    services.caddy.virtualHosts.${fqdn} = {
      extraConfig = ''
        	route /api* {
            uri strip_prefix /api
            reverse_proxy http://127.0.0.1:14702
          }

          route /ws {
            @upgrade {
              header Connection *Upgrade*
              header Upgrade websocket
            }

            uri strip_prefix /ws
            reverse_proxy @upgrade http://127.0.0.1:9000
          }

          route /autumn* {
            uri strip_prefix /autumn
            reverse_proxy http://127.0.0.1:14704
          }

          route /january* {
            uri strip_prefix /january
            reverse_proxy http://127.0.0.1:7000
          }

          reverse_proxy http://127.0.0.1:5000
      '';
    };
  };
}
