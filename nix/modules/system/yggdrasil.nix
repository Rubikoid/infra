{ config, ... }:

{
  sops.secrets."yggdrasil.json" = {
    sopsFile = ../../secrets + "/${config.device}/yggdrasil.json";
    format = "json";
  };

  services.yggdrasil = {
    enable = true;
    openMulticastPort = true;
    group = "wheel";
    denyDhcpcdInterfaces = [ "ygg" ];
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
