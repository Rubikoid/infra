{ lib, config, secrets, pkgs, ... }:
{
  options.rubikoid.services.pdns =
    let
      types = lib.types;
    in
    {
      keys = {
        web = lib.mkOption {
          type = types.str;
          default = secrets.pdns-keys.web;
        };

        api = lib.mkOption {
          type = types.str;
          default = secrets.pdns-keys.api;
        };
      };

      dns-server = {
        host = lib.mkOption {
          type = types.str;
          default = "127.0.0.1";
        };

        port = lib.mkOption {
          type = types.port;
          default = 5300;
        };
      };

      web-server = {
        # host = lib.mkOption {
        #   type = types.str;
        #   default = "127.0.0.1";
        # };

        port = lib.mkOption {
          type = types.port;
          default = 5400;
        };
      };

      admin = {
        host = lib.mkOption {
          type = types.str;
          default = "127.0.0.1";
        };

        port = lib.mkOption {
          type = types.port;
          default = 5500;
        };
      };

      caddyName = lib.mkOption {
        type = types.str;
        default = "pdns-admin";
      };
    };

  config =
    let
      cfg = config.rubikoid.services.pdns;
    in
    {
      networking = {
        resolvconf.useLocalResolver = true;

        firewall = {
          allowedTCPPorts = [ 53 ]; # cfg.dns-server.port
          allowedUDPPorts = [ 53 ]; # cfg.dns-server.port
        };
      };

      systemd.services.powerdns-admin = {
        serviceConfig.StateDirectory = "powerdns-admin";
      };

      services = {
        powerdns = {
          enable = true;

          secretFile = null;

          extraConfig = ''
            local-address=${cfg.dns-server.host}
            local-port=${toString cfg.dns-server.port}

            launch=gsqlite3
            gsqlite3-database=/backup-drive/data/pdns/pdns.sqlite3

            webserver=yes
            webserver-port=${toString cfg.web-server.port}
            webserver-password=${cfg.keys.web}

            api=yes
            api-key=${cfg.keys.api}
          '';
        };

        pdns-recursor = {
          enable = true;

          dns = {
            allowFrom = [
              "0.0.0.0/0"
              "::/0"
            ];
          };

          forwardZones = {
            "lab" = "127.0.0.1:${toString cfg.dns-server.port}";

            "lab.rubikoid.ru" = "127.0.0.1:${toString cfg.dns-server.port}";
            "${secrets.dns.private}" = "127.0.0.1:${toString cfg.dns-server.port}";

            "bk252" = "[${secrets.yggdrasil.nodes.kks.omega}]:5300;[${secrets.yggdrasil.nodes.kks.delta}]:5300";
          };

          # api = {
          #   address = "127.0.0.1";
          #   port = 8082; # default... e
          # };

          settings = {
            webserver = false;
          };
        };

        powerdns-admin = {
          enable = true;

          config = ''
            BIND_ADDRESS = '${cfg.admin.host}'
            PORT = ${toString cfg.admin.port}

            SQLALCHEMY_DATABASE_URI = 'sqlite:////var/lib/powerdns-admin/pdns-admin.sqlite3'

            CAPTCHA_ENABLE = False
          '';

          secretKeyFile = "/etc/machine-id"; # FIXME: vulnerable...
          saltFile = "/etc/machine-id"; # FIXME: vulnerable...

          extraArgs = [ "-b" "${cfg.admin.host}:${toString cfg.admin.port}" ];
        };

        rubikoid.http.services.pdns-admin = {
          name = cfg.caddyName;
          hostOnHost = cfg.admin.host;
          inherit (cfg.admin) port;
        };
      };
    };
}
