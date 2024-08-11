{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  serviceName = "xandikos";
  cfg = config.rubikoid.services.${serviceName};
in
{
  options.rubikoid.services.${serviceName} = {
    port = lib.mkOption {
      type = types.port;
      default = 21182;
    };

    caddyName = lib.mkOption {
      type = types.str;
      default = "cal";
    };
  };

  config = {
    services.xandikos = {
      enable = true;
      port = cfg.port;
      extraOptions = [
        "--autocreate"
        "--defaults"
        "--current-user-principal /rubikoid"
        "--dump-dav-xml"
        "--debug"
      ];
    };
    rubikoid.http.services.${serviceName} = {
      name = cfg.caddyName;
      inherit (cfg) port;
    };
  };
}
