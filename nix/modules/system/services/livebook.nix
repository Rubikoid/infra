{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  cfg = config.rubikoid.services.livebook;

  private-url = "${cfg.caddyName}.${secrets.dns.private}";
in
{
  options.rubikoid.services.livebook = {
    host = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = types.port;
      default = 8567;
    };

    caddyName = lib.mkOption {
      type = types.str;
      default = "livebook";
    };
  };

  config = {
    services.livebook =
      let
        env = pkgs.writeText "livebook.env"
          '' 
          LIVEBOOK_TOKEN_ENABLED=false
          LIVEBOOK_SHUTDOWN_ENABLED=false
          '';
      in
      {
        enableUserService = false;

        address = cfg.host;
        port = cfg.port;

        # erlang_node_short_name = "livebook";
        erlang_node_name = "livebook@127.0.0.1";

        environmentFile = env;
      };

    services.caddy.virtualHosts.${private-url} = {
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString cfg.port}
        import stepssl_acme
      '';
    };
  };
}
