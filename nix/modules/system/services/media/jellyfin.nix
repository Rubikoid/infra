{ lib, config, secrets, pkgs, ... }:
let
  types = lib.types;
  cfg = config.rubikoid.services.jellyfin;
in
{
  options.rubikoid.services.jellyfin = {
    caddyName = lib.mkOption {
      type = types.str;
      default = "jellyfin";
    };
  };

  config = {
    services.jellyfin = {
      enable = true;
      openFirewall = false;
    };
    # rubikoid.services.media.mediaWriters = [ config.services.jellyfin.user ];

    rubikoid.http.services.jellyfin = {
      name = cfg.caddyName;
      hostOnHost = "127.0.0.1";
      port = 8096;
    };
  };
}
