{ config, secrets, lib, ... }:
{
  options.rubikoid.services.yggdrasil =
    let
      types = lib.types;
    in
    {
      startMulticast = lib.mkOption {
        type = types.bool;
        default = true;
      };

      openPublic = lib.mkOption {
        type = types.bool;
        default = false;
      };
    };

  config =
    let
      cfg = config.rubikoid.services.yggdrasil;
    in
    {
      sops.secrets."yggdrasil.hjson" = {
        sopsFile = secrets.deviceSecrets + "/yggdrasil.hjson";
        format = "binary";
      };

      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openPublic [ secrets.yggdrasil.publicPort ];

      services.yggdrasil = {
        enable = true;
        openMulticastPort = cfg.startMulticast;
        group = "wheel";
        denyDhcpcdInterfaces = [ "ygg" ];

        configFile = config.sops.secrets."yggdrasil.hjson".path;
        settings = lib.recursiveUpdate
          {
            IfName = "ygg";

            Listen =
              if cfg.openPublic
              then [ "tls://0.0.0.0:${secrets.yggdrasil.publicPort}?password=${secrets.yggdrasil.mainPassword}" ]
              else [ ];

            MulticastInterfaces =
              if cfg.startMulticast
              then
                map
                  (pw: {
                    Regex = ".*";
                    Beacon = true;
                    Listen = true;
                    Port = 0;
                    Priority = 0;
                    Password = pw;
                  })
                  secrets.yggdrasil.passwords
              else [ ];
          }
          secrets.yggdrasil.settings;
      };
    };
}
