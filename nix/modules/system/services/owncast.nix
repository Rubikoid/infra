{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  serviceName = "owncast";
  cfg = config.rubikoid.services.owncast;
in
{
  options.rubikoid.services.owncast = {
    port = lib.mkOption {
      type = types.port;
      default = 18612;
    };

    caddyName = lib.mkOption {
      type = types.str;
      default = serviceName;
    };
  };

  config = {
    services.owncast = {
      enable = true;
      listen = "127.0.0.1";
      port = cfg.port;
      openFirewall = true;
    };

    # rubikoid.http.services.owncast = {
    #   name = cfg.caddyName;
    #   inherit (cfg) port;
    # };
  };
}
