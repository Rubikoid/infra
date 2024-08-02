{ lib, config, secrets, pkgs, ... }:
let
  types = lib.types;
  cfg = config.rubikoid.services.arrs;
in
{
  imports = [
    ./qbittorrent.nix
    ./media.nix
  ];

  options.rubikoid.services.arrs = {
    qbittorrent = {
      caddyName = lib.mkOption {
        type = types.str;
        default = "torr";
      };

      port = lib.mkOption {
        type = types.int;
        default = 21000;
      };

      torrentPort = lib.mkOption {
        type = types.int;
        default = 10261;
      };
    };
  };

  config = {
    services.qbittorrent = {
      enable = true;
      dataDir = "${config.rubikoid.services.media.baseDataFolder}/qbittorrent";
      port = cfg.qbittorrent.port;
      openFilesLimit = 16384; # 32768;
      openFirewall = false;
    };
    rubikoid.services.media.mediaWriters = [ config.services.qbittorrent.user ];

    networking.firewall = {
      allowedTCPPorts = [ cfg.qbittorrent.torrentPort ];
      allowedUDPPorts = [ cfg.qbittorrent.torrentPort ];
    };

    rubikoid.http.services.qbittorrent = {
      name = cfg.caddyName;
      hostOnHost = "127.0.0.1";
      inherit (cfg) port;
    };
  };
}
