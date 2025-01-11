{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  serviceName = "gns3";
  cfg = config.rubikoid.services.gns3;
in
{
  options.rubikoid.services.gns3 = {

  };

  config = {
    networking.firewall.allowedTCPPortRanges = [
      {
        from = 15000;
        to = 16000;
      }
    ];

    services.gns3-server = {
      enable = true;

      dynamips.enable = true;
      vpcs.enable = true;
      ubridge.enable = true;

      settings = {
        Server = {
          host = secrets.dns.data.nodes.kubic.at.home;
          port = 15000;

          console_start_port_range = 15001;
          console_end_port_range = 16000;

          udp_start_port_range = 16000;
          udp_end_port_range = 17000;
        };
      };
    };
  };
}
