{ lib, pkgs, ... }:

{
  virtualisation.oci-containers.containers =
    let
      ha_version = "2023.7.2";
      mosquitto_version = "2.0.15";
      zigbee2mqtt_version = "1.32.1";
      zigbee_device_id = "usb-ITEAD_SONOFF_Zigbee_3.0_USB_Dongle_Plus_V2_20221031155527-if00";
    in
    {
      homeassistant = {
        image = "ghcr.io/home-assistant/home-assistant:${ha_version}";

        environment.TZ = "Europe/Moscow";

        volumes = [
          "home-assistant:/config"
        ];

        extraOptions = [
          "--network=host"
          "--device=/dev/serial/by-id/${zigbee_device_id}:/dev/ttyACM0"
        ];
      };

      mosquitto = {
        image = "eclipse-mosquitto:${mosquitto_version}";

        environment.TZ = "Europe/Moscow";

        volumes = [
          "${./ha/mosquitto.conf}:/mosquitto/config/mosquitto.conf:ro"
          "mosquitto_data:/mosquitto/data"
          "mosquitto_logs:/mosquitto/log"
        ];

        extraOptions = [
          "--network=host"
        ];
      };

      zigbee2mqtt = {
        image = "koenkk/zigbee2mqtt:${zigbee2mqtt_version}";

        environment.TZ = "Europe/Moscow";

        volumes = [
          "${./ha/zigbee2mqtt.yaml}:/app/data/configuration.yaml"
          "zigbee2mqtt_data:/app/data"
          "/run/udev:/run/udev:ro"
        ];

        extraOptions = [
          "--network=host"
          "--device=/dev/serial/by-id/${zigbee_device_id}:/dev/ttyACM0"
        ];
      };
    };

  # networking.firewall.allowedTCPPorts = [ 8123 40000 ];

  # services.zigbee2mqtt = {
  #   enable = true;
  #   settings = {
  #     homeassistant = true;
  #     permit_join = true;
  #     serial = {
  #       port = "/dev/ttyACM0";
  #     };
  #   };
  # };

  # services.mosquitto = {
  #   enable = true;

  #   settings = { 

  #   };
  # };

  # services.home-assistant = {
  #   enable = true;
  #   openFirewall = true;

  #   extraComponents = [
  #     # Components required to complete the onboarding
  #     "esphome"
  #     "met"
  #     "radio_browser"
  #     "mqtt"
  #     "homekit"
  #     "homekit_controller"
  #   ];
  #   config = {
  #     # Includes dependencies for a basic setup
  #     # https://www.home-assistant.io/integrations/default_config/
  #     default_config = { };
  #   };
  # };
}
