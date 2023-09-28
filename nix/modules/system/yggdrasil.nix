{ config, lib, ... }:

{
  sops.secrets."yggdrasil.hjson" = {
    sopsFile = config.deviceSecrets + "/yggdrasil.hjson";
    format = "binary";
  };

  services.yggdrasil = {
    enable = true;
    openMulticastPort = lib.mkDefault true;
    group = "wheel";
    denyDhcpcdInterfaces = [ "ygg" ];

    configFile = config.sops.secrets."yggdrasil.hjson".path;
    settings = {
      IfName = "ygg";

      MulticastInterfaces = [
        {
          Regex = ".*";
          Beacon = true;
          Listen = true;
          Port = 0;
          Priority = 0;
        }
      ];
    };
  };
}
