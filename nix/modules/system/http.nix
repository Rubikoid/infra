{ lib, config, secrets, ... }:

let
  types = lib.types;
  cfg = config.rubikoid.http;
in
{
  options.rubikoid.http = {
    services = lib.mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }:
        let
          service = cfg.services.${name};
        in
        {
          options = {
            name = lib.mkOption {
              type = types.str;
              default = name;
            };

            host = lib.mkOption {
              type = types.str;
              default = config.networking.hostName;
            };

            port = lib.mkOption {
              type = types.port;
            };

            hostOnHost = lib.mkOption {
              type = types.str;
              default = "127.0.0.1";
            };

            caddyConfig = lib.mkOption {
              type = types.str;
              default = ''
                reverse_proxy http://${service.hostOnHost}:${toString service.port}
                import stepssl_acme
              '';
            };

            fqdn = lib.mkOption {
              type = types.str;
              default = "${service.name}.${config.rubikoid.dns.rootZone}";
            };

          };
        }));
      default = { };
    };
  };

  config = {
    rubikoid.dns.services = (lib.mapAttrs' (name: service: lib.nameValuePair service.name service.host) cfg.services);
    services.caddy.virtualHosts = (lib.mapAttrs'
      (name: service:
        lib.nameValuePair
          service.fqdn
          { extraConfig = service.caddyConfig; }
      )
      cfg.services);
  };
}
