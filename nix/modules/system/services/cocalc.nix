{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  cfg = config.rubikoid.services.overleaf;
in
{
  options.rubikoid.services.overleaf = {
    version = lib.mkOption {
      type = types.str;
      # default = "5bcc1bd4bcec66ddf4349c55cfabb6bd4a9f0d55c5f6e09bd6b166d26209b20b"; # sagemathinc/cocalc-docker:latest at 17.01.2024
      default = "1.1-full";
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
      default = "/backup-drive/data/cocalc";
    };
  };

  config = {
    virtualisation.oci-containers.containers = {
      cocalc = {
        # image = "sagemathinc/cocalc-docker@sha256:${cfg.version}";
        image = "cocalc:${cfg.version}";

        environment = {
          COCALC_NO_IDLE_TIMEOUT = "yes";
          NOSSL = "true";
        };

        ports = [
          "${cfg.host}:${toString cfg.port}:80"
        ];

        volumes = [
          # "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"
          "${cfg.dataFolder}:/projects"
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

# echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
