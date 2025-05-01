{ lib, config, pkgs, secrets, ... }:

let
  rCfg = config.rubikoid;
  cfg = rCfg.l2tpServer;
in
{
  options.rubikoid.l2tpServer = with lib; {

  };

  config = {
    sops.secrets.l2tp_key = { };
    sops.secrets.lt2p_auth = { };

    services = {
      strongswan = {
        enable = true;
        setup = { };
        connections.l2tp-vpn = {
          fragmentation = "yes";
          dpdaction = "clear";
          dpdtimeout = "90s";
          dpddelay = "30s";

          # keyexchange = "ikev2";
          ike = "aes256-sha-modp1024-esn-noesn";
          esp = "aes256-sha1-sha256-modp2048-modp4096-modp1024-esn-noesn";

          # ike = "aes128-sha256-modp3072";
          # esp = "aes128-sha256-modp3072";

          type = "transport";

          leftsubnet = "%dynamic[/1701]";
          leftauth = "psk";
          # leftid = "@srvl2tp";

          rightsubnet = "%dynamic";
          rightauth = "psk";

          auto = "add";
        };

        secrets = [
          config.sops.secrets.l2tp_key.path
        ];
      };

      xl2tpd = {
        enable = true;
        serverIp = "172.27.0.1"; # secrets.dns.public-ips.dedic; # TODO: fixme
        clientIpRange = "172.27.0.2-10";
        extraPppdOptions = ''
          debug
          dump
        '';
        extraXl2tpOptions = ''
          [global]
          auth file = ${config.sops.secrets.l2tp_key.path}

          [lns default]
          hidden bit = no
          length bit = yes
          require authentication = yes
          ppp debug = yes
        '';
      };
    };

    networking.firewall.interfaces.eth0.allowedUDPPorts = [
      500
      1701
      4500
    ];
  };
}
