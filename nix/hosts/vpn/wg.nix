{ pkgs, secrets, config, ... }:

let
  ipt = "${pkgs.iptables}/bin/iptables";
in
{
  sops.secrets."firewall_setup.sh" = {
    sopsFile = secrets.deviceSecrets + "/firewall_setup.sh";
    format = "binary";
  };

  sops.templates."fw.sh" = {
    mode = "0500";
    content = ''
      #!${pkgs.bash}/bin/bash

      IPT="${ipt}"
      OUT=ens3 # TODO: fix it sometimes...

      A=$1 # action: -A/-D
      I=$2 # wg interface

      port_forward() {
        iptables -t nat $A PREROUTING -i $OUT -p tcp --dport $2 -j DNAT --to-destination $1:$2
        iptables -t nat $A PREROUTING -i $OUT -p udp --dport $2 -j DNAT --to-destination $1:$2
      }
  
      ${config.sops.placeholder."firewall_setup.sh"}
    '';
  };

  sops.secrets."wg_head.conf" = {
    sopsFile = secrets.deviceSecrets + "/wg_head.conf";
    format = "binary";
  };

  sops.secrets."wg_peers.conf" = {
    sopsFile = secrets.deviceSecrets + "/wg_peers.conf";
    format = "binary";
  };

  sops.templates."wg.conf".content = ''
    ${config.sops.placeholder."wg_head.conf"}
    PostUp   = ${config.sops.templates."fw.sh".path} '-A' "%i"
    PostDown = ${config.sops.templates."fw.sh".path} '-D' "%i"
    
    ${config.sops.placeholder."wg_peers.conf"}
  '';

  networking = {
    firewall.allowedUDPPorts = [ 52812 ];
    wg-quick.interfaces.home.configFile = config.sops.templates."wg.conf".path;
  };

  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];
}
