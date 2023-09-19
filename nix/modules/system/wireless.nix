{ config, ... }:

{
  # stolen from https://www.reddit.com/r/NixOS/comments/zneyil/using_sopsnix_to_amange_wireless_secrets/j0h1vie/
  sops.secrets."wireless.env" = {
    sopsFile = ../../secrets + "/${config.device}/wireless.env";
    format = "dotenv";
  };

  networking.wireless = {
    environmentFile = config.sops.secrets."wireless.env".path;
    networks = {
      "@home_uuid@" = { psk = "@home_psk@"; };
      "@bk252_uuid@" = { psk = "@bk252_psk@"; };
      "@iphone_uuid@" = { psk = "@iphone_psk@"; };
      "@pt_uuid@" = { psk = "@pt_psk@"; };
    };
  };
}
