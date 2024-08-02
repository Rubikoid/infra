{ lib, config, secrets, inputs, ... }:
let
  types = lib.types;
  cfg = config.rubikoid.services.ygg-map;
in
{
  imports = [ inputs.ygg-map.nixosModules.default ];

  options.rubikoid.services.ygg-map = {
    caddyName = lib.mkOption {
      type = types.str;
      default = "map";
    };
  };

  config.services = {
    ygg-map = {
      enable = true;
      openFirewall = true;
      http.host = "::";
    };

    rubikoid.http.services.paperless = {
      name = cfg.caddyName;
      hostOnHost = "[::1]";
      inherit (config.services.ygg-map.http) port;
    };

    caddy.virtualHosts."http://map.bk252" = {
      extraConfig = ''
        reverse_proxy http://[::1]:${toString config.services.ygg-map.http.port}
        import stepssl_acme
      '';
    };
  };
}
