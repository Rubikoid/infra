{ lib, config, secrets, pkgs, ... }:
{
  options.rubikoid.services =
    let
      types = lib.types;
    in
    {
      gitea = {
        host = lib.mkOption {
          type = types.str;
          default = "127.0.0.1";
        };

        port = lib.mkOption {
          type = types.port;
          default = 3000;
        };

        caddyName = lib.mkOption {
          type = types.str;
          default = "gitea";
        };
      };

      drone = {
        version = lib.mkOption {
          type = types.str;
          default = "2.4";
        };

        host = lib.mkOption {
          type = types.str;
          default = "127.0.0.1";
        };

        port = lib.mkOption {
          type = types.port;
          default = 3001;
        };

        caddyName = lib.mkOption {
          type = types.str;
          default = "drone";
        };

        secrets = {
          gitea-client-id = lib.mkOption {
            type = types.str;
            default = secrets.drone.gitea-client-id;
          };
          gitea-client-secret = lib.mkOption {
            type = types.str;
            default = secrets.drone.gitea-client-secret;
          };
          rpc-secret = lib.mkOption {
            type = types.str;
            default = secrets.drone.rpc-secret;
          };
          cookie-secret = lib.mkOption {
            type = types.str;
            default = secrets.drone.cookie-secret;
          };
        };
      };
    };

  config =
    let
      cfg-gitea = config.rubikoid.services.gitea;
      cfg-drone = config.rubikoid.services.drone;
      gitea-public-domain = "${cfg-gitea.caddyName}.${secrets.dns.public}";
      drone-public-domain = "${cfg-drone.caddyName}.${secrets.dns.public}";
    in
    {
      services = {
        gitea = {
          enable = true;

          appName = "Rubikoid's gitea";

          stateDir = "/data/gitea";
          # customDir = "${config.services.gitea.stateDir}/gitea";
          # repositoryRoot = "${config.services.gitea.stateDir}/git/repositories";

          lfs = {
            enable = true;
            # contentDir = "${config.services.gitea.stateDir}/git/lfs";
          };

          dump = {
            enable = true;
            type = "tar.xz";
          };

          database = {
            # path = "${config.services.gitea.stateDir}/gitea.db";
            type = "sqlite3";
            createDatabase = false;
          };

          settings = {
            session.COOKIE_SECURE = true;
            service = {
              DISABLE_REGISTRATION = true;
              REQUIRE_SIGNIN_VIEW = true;
              REGISTER_EMAIL_CONFIRM = false;
              ENABLE_NOTIFY_MAIL = false;
              ALLOW_ONLY_EXTERNAL_REGISTRATION = false;
              ENABLE_CAPTCHA = false;
              DEFAULT_KEEP_EMAIL_PRIVATE = true;
              DEFAULT_ALLOW_CREATE_ORGANIZATION = true;
              DEFAULT_ENABLE_TIMETRACKING = true;
            };
            server = {
              DOMAIN = "${gitea-public-domain}";

              SSH_PORT = 2222;

              HTTP_ADDR = cfg-gitea.host;
              HTTP_PORT = cfg-gitea.port; # default
            };

            # indexer = { };
          };
        };

        gitea-actions-runner.instances.core = {
          enable = false;
          name = "core";

          url = "https://${gitea-public-domain}";
          tokenFile = "";

          labels = [
            "debian-latest:docker://alpine:3"
          ];

          settings = { };
        };
      };

      virtualisation.oci-containers.containers = {
        drone-server = {
          image = "drone/drone:${cfg-drone.version}";
          environment = {
            DRONE_SERVER_PROTO = "https";
            DRONE_SERVER_HOST = drone-public-domain;
            DRONE_SERVER_PRIVATE_MODE = "true";

            DRONE_GITEA_CLIENT_ID = cfg-drone.secrets.gitea-client-id;
            DRONE_GITEA_CLIENT_SECRET = cfg-drone.secrets.gitea-client-secret;
            DRONE_GITEA_SERVER = "https://${gitea-public-domain}";

            DRONE_GIT_ALWAYS_AUTH = "true";
            DRONE_RPC_SECRET = cfg-drone.secrets.rpc-secret; # secret
            DRONE_USER_FILTER = "Rubikoid";
            DRONE_USER_CREATE = "username:Rubikoid,machine:false,admin:true";
            DRONE_COOKIE_SECRET = cfg-drone.secrets.cookie-secret;
          };

          ports = [
            "${toString cfg-drone.host}:${toString cfg-drone.port}:80"
          ];

          volumes = [
            "/data/drone:/data"
          ];
        };

        drone-agent = {
          image = "drone/drone-runner-docker:linux-amd64";
          environment = {
            DRONE_RPC_PROTO = "https";
            DRONE_RPC_HOST = drone-public-domain;
            DRONE_RPC_SECRET = cfg-drone.secrets.rpc-secret;
          };

          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock"
          ];

          dependsOn = [ "drone-server" ];
        };

        outer_docker_registry = {
          image = "registry:2";

          ports = [
            # "127.0.0.1:5000:5000"
          ];

          volumes = [
            "/data/docker_registry:/var/lib/registry"
          ];
        };
      };

      services.caddy.virtualHosts = {
        ${gitea-public-domain} = {
          extraConfig = ''
            reverse_proxy http://127.0.0.1:${toString cfg-gitea.port}
          '';
        };
        ${drone-public-domain} = {
          extraConfig = ''
            reverse_proxy http://127.0.0.1:${toString cfg-drone.port}
          '';
        };
      };
    };
}
