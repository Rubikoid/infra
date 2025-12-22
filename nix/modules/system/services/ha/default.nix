{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  serviceName = "ha";
  cfg = config.rubikoid.services.ha;
in
{
  options.rubikoid.services.ha = {
    enable = lib.mkEnableOption "Enable HA";

    z2m_device = lib.mkOption {
      type = types.str;
    };

  };

  config = lib.mkIf cfg.enable {
    systemd.services.zigbee2mqtt.after = [ "mosquitto.service" ];
    systemd.services."home-assistant".after = [ "mosquitto.service" ];

    networking.firewall.allowedTCPPorts = [ 8120 ];

    services = {
      mosquitto = {
        enable = true;

        listeners = [
          {
            address = "0.0.0.0"; # TODO: ...
            port = 1883;
            settings.allow_anonymous = true;
            omitPasswordAuth = false;
            acl = [ "topic readwrite #" ];

            # users.hass = {
            #   acl = [
            #     "readwrite #"
            #   ];
            #   passwordFile = config.sops.secrets."mqtt/pass/hass".path;
            # };

            # users."${config.services.zigbee2mqtt.settings.mqtt.user}" = {
            #   acl = [
            #     "readwrite #"
            #   ];
            #   passwordFile = config.sops.secrets."mqtt/pass/zigbee2mqtt".path;
            # };
          }
        ];
      };

      zigbee2mqtt = {
        enable = true;
        package = pkgs.nixpkgs-collection.nixpkgs-master.zigbee2mqtt_2;
        settings = {
          permit_join = true;

          serial = {
            port = cfg.z2m_device;
            adapter = "ember";
          };

          frontend = {
            enabled = true;

            host = "0.0.0.0"; # TODO: close host and move it to options
            port = 8120;

            url = "http://192.168.10.30:8120"; # TODO: fix this
          };
        };
      };

      home-assistant = {
        enable = true;

        openFirewall = true; # TODO option

        extraComponents = [
          "default_config"
          "met"
          "esphome"
          "rpi_power"
          "mqtt"
          "homekit"
          "homekit_controller"
        ];

        config = {
          homeassistant = {
            language = "ru";

            country = "RU";
            currency = "RUB";

            unit_system = "metric";
            temperature_unit = "C";
          };

          http = {
            use_x_forwarded_for = true;
            trusted_proxies = [ secrets.yggdrasil.nodes.rubikoid.msite-new ];
          };
        };
      };
    };
  };
}
