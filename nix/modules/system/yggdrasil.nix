{ config, secrets, lib, ... }:

let
  scr = secrets.yggdrasil;
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

      services.yggdrasil = {
        enable = true;
        openMulticastPort = cfg.startMulticast;
        group = "wheel";
        denyDhcpcdInterfaces = [ "ygg" ];

        configFile = config.sops.secrets."yggdrasil.hjson".path;
        settings = lib.recursiveUpdate
          {
            IfName = "ygg";

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
                  scr.passwords
              else [ ];
          }
          scr.settings;
      };
    };
}
