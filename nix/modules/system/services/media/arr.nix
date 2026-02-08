{ lib, config, secrets, pkgs, ... }:
let
  types = lib.types;
  cfg = config.rubikoid.services.arrs;
  mCfg = config.rubikoid.services.media;
in
{
  imports = [
    # ./qbittorrent.nix
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
      openFirewall = false;

      profileDir = "${mCfg.baseDataFolder}/qbittorrent";
      webuiPort = cfg.qbittorrent.port;
      torrentingPort = cfg.qbittorrent.torrentPort;

      extraArgs = [
        "--confirm-legal-notice"
      ];
      # openFilesLimit = 16384; # 32768;

      serverConfig = {
        BitTorrent = {
          MergeTrackersEnabled = true;
          Session = {
            AddTorrentToTopOfQueue = true;

            FinishedTorrentExportDirectory = "${mCfg.baseDataFolder}/qbittorrent/files-finished";

            DefaultSavePath = "${mCfg.mediaDataFolder}/generic";
            TempPath = "${mCfg.mediaDataFolder}/downloading";

            Interface = "enp6s0"; # idk
            InterfaceName = "enp6s0"; # idk

            MaxActiveDownloads = 5;
            MaxActiveTorrents = 8;

            MaxConnections = 1000;
            MaxConnectionsPerTorrent = 200;

            MaxUploads = 30;
            MaxUploadsPerTorrent = 10;

            ReannounceWhenAddressChanged = true;

            Tags = lib.strings.join ", " [
              # resolution
              "400p"
              "1080p"
              "1440p"
              "2160p"
              # source info
              "BDRemux"
              "BDRip"
              "WEBDL"
              "WEBRip"
              "HEVC"
              # series
              "HarryPotter"
              "Marvel"
              "MKNR"
              "TBBT"
              "VampireDiaries"
              "Советская классика"
              # format
              "Anime"
              "Movie"
              "Show"
              # language
              "rus"
              "eng"
            ];
          };
        };
        Preferences = {
          General.Locale = "en";
          WebUI = {
            AlternativeUIEnabled = false;
            # RootFolder = "${pkgs.vuetorrent}/public";

            # it's hashed and anyway this service is private, i don't care now.
            Password_PBKDF2 = "@ByteArray(yJzV11deN2v53tbnwNiRuA==:y1AO4LjaT3IjYZ8z94fjyPP2wDRwKjpcy7tMVqYt8uCFxsQIIfB4yMkr4xJS2DYC+95R21vz3HHcRhLl3+B7sA==)";
            ReverseProxySupportEnabled = true;
            ServerDomains = "torr.${secrets.dns.private}";
            TrustedReverseProxiesList = "127.0.0.1";
          };
        };
      };
    };
    rubikoid.services.media.mediaWriters = [ config.services.qbittorrent.user ];

    networking.firewall = {
      allowedTCPPorts = [ cfg.qbittorrent.torrentPort ];
      allowedUDPPorts = [ cfg.qbittorrent.torrentPort ];
    };

    rubikoid.http.services.qbittorrent = {
      name = cfg.qbittorrent.caddyName;
      hostOnHost = "127.0.0.1";
      inherit (cfg.qbittorrent) port;
    };
  };
}
