{ lib, config, secrets, pkgs, ... }:
{
  imports = [
    ./qbittorrent.nix
    ./media.nix
  ];

  options.rubikoid.services =
    let
      types = lib.types;
    in
    {
      arrs = {
        qbittorrent = {
          hostname = lib.mkOption {
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
    };

  config =
    let
      cfg = config.rubikoid.services.arrs;
    in
    {
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

      services.caddy.virtualHosts = {
        "${cfg.qbittorrent.hostname}.${secrets.dns.private}" = {
          extraConfig = ''
            reverse_proxy http://127.0.0.1:${toString cfg.qbittorrent.port}
            import stepssl_acme
          '';
        };
      };
    };
}
