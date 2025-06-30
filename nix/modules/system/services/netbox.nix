{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  serviceName = "netbox";
  cfg = config.rubikoid.services.netbox;
in
{
  options.rubikoid.services.netbox = {
    port = lib.mkOption {
      type = types.port;
      default = 21723;
    };

    caddyName = lib.mkOption {
      type = types.str;
      default = serviceName;
    };
  };

  config = {
    sops.secrets."netbox-key" = {
      sopsFile = secrets.deviceSecrets + "/secrets.yaml";
      owner = "netbox";
      group = "netbox";
      mode = "400";
    };

    services.netbox = {
      enable = true;

      package = pkgs.nixpkgs-collection.nixpkgs-stable.netbox_4_1; # TODO: wtf?
      port = cfg.port;

      secretKeyFile = config.sops.secrets."netbox-key".path;

      settings = {
        ALLOWED_HOSTS = [
          config.rubikoid.http.services.netbox.fqdn
          # "127.0.0.1"
          # "[::1]"
        ];

      };

      extraConfig = "";

      plugins =
        py: with py; [

        ];
    };
    rubikoid.http.services.netbox =
      let
        svcCfg = config.rubikoid.http.services.netbox;
      in
      {
        name = cfg.caddyName;
        hostOnHost = "[::1]";
        inherit (cfg) port;

        caddyConfig = ''
          encode gzip zstd

          handle_path /static/* {
            root * ${config.services.netbox.settings.STATIC_ROOT}
            file_server
          }

          reverse_proxy http://${svcCfg.hostOnHost}:${toString svcCfg.port}
          import stepssl_acme
        '';
      };
  };
}
