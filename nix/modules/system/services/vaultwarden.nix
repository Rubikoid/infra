{ lib, config, secrets, pkgs, ... }:
{
  options.rubikoid.services.vaultwarden =
    let
      types = lib.types;
    in
    {
      host = lib.mkOption {
        type = types.str;
        default = "127.0.0.1";
      };

      port = lib.mkOption {
        type = types.port;
        default = 8222;
      };

      caddyName = lib.mkOption {
        type = types.str;
        default = "vaultwarden";
      };
    };

  config =
    let
      cfg = config.rubikoid.services.vaultwarden;
    in
    {
      services.vaultwarden = {
        enable = true;

        config = {
          ADMIN_TOKEN = secrets.vaultWardenAdmin;

          DOMAIN = "https://${config.rubikoid.http.services.vaultwarden.fqdn}";
          SIGNUPS_ALLOWED = false;

          ROCKET_ADDRESS = cfg.host;
          ROCKET_PORT = cfg.port;

          IP_HEADER = "X-Forwarded-For";
        };
      };

      rubikoid.http.services.vaultwarden = {
        name = cfg.caddyName;
        hostOnHost = cfg.host;
        inherit (cfg) port;
      };
    };
}
