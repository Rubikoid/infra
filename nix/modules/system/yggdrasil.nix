{ mode, config, secrets, lib, ... }:
let
  cfg = config.rubikoid.services.yggdrasil;
in
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

  config = lib.recursiveUpdate
    {
      sops.secrets."yggdrasil.hjson" = {
        sopsFile = secrets.deviceSecrets + "/yggdrasil.hjson";
        format = "binary";
      };

      services.yggdrasil = {
        enable = true;

        configFile = config.sops.secrets."yggdrasil.hjson".path;
        settings = lib.recursiveUpdate
          {
            Listen =
              if cfg.openPublic
              then [ "tls://0.0.0.0:${toString secrets.yggdrasil.publicPort}?password=${secrets.yggdrasil.mainPassword}" ]
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
    }
    (lib.optionalAttrs (mode == "NixOS")
      {
        networking.firewall.allowedTCPPorts = lib.mkIf cfg.openPublic [ secrets.yggdrasil.publicPort ];
        services.yggdrasil = {
          settings.IfName = "ygg";
          openMulticastPort = cfg.startMulticast;
          group = "wheel";
          denyDhcpcdInterfaces = [ "ygg" ];
        };
      }
    );
}
