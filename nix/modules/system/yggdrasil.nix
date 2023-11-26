{ config, secrets, lib, ... }:

let
  scr = secrets.yggdrasil;
in
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

      MulticastInterfaces = map
        (pw: {
          Regex = ".*";
          Beacon = true;
          Listen = true;
          Port = 0;
          Priority = 0;
          Password = pw;
        })
        scr.passwords;
    };
  };
}
