{ config, pkgs, ... }:

{
  networking.resolvconf.extraConfig = ''
    unbound_conf=/etc/unbound-resolvconf.conf
  '';

  services.unbound = {
    enable = true;
    resolveLocalQueries = true;

    settings = {
      include = [
        "/etc/unbound-resolvconf.conf"
      ];
      server = {
        interface = [ "127.0.0.1" ];

      remote-control.control-enable = true;
    };
  };
}
