{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  serviceName = "atuin";
  cfg = config.rubikoid.services.atuin;
in
{
  options.rubikoid.services.atuin = {
    port = lib.mkOption {
      type = types.port;
      default = 15623;
    };

    caddyName = lib.mkOption {
      type = types.str;
      default = serviceName;
    };
  };

  config = {
    services.atuin = {
      enable = true;
      port = cfg.port;

      maxHistoryLength = 16 * 1024; # 16kB
      openRegistration = false;
    };

    rubikoid.http.services.atuin = {
      name = cfg.caddyName;
      inherit (cfg) port;
    };
  };
}
