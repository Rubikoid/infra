{ lib, config, secrets, inputs, ... }:
{
  imports = [ inputs.ygg-map.nixosModules.default ];

  options.rubikoid.services.ygg-map =
    let
      types = lib.types;
    in
    {
      caddyName = lib.mkOption {
        type = types.str;
        default = "map";
      };
    };

  config.services =
    let
      cfg = config.rubikoid.services.ygg-map;
    in
    {
      ygg-map = {
        enable = true;
        openFirewall = true;
        http.host = "::";
      };

      caddy.virtualHosts = {
        "${cfg.caddyName}.${secrets.dns.private}" = {
          extraConfig = ''
            reverse_proxy http://[::1]:${toString config.services.ygg-map.http.port}
            import stepssl_acme
          '';
        };
        "http://map.bk252" = {
          extraConfig = ''
            reverse_proxy http://[::1]:${toString config.services.ygg-map.http.port}
            import stepssl_acme
          '';
        };
      };
    };
}
