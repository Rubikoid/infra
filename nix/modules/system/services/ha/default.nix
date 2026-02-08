{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  serviceName = "ha";
  cfg = config.rubikoid.services.ha;
in
{
  imports = [
    ./otbr.nix
  ];

  options.rubikoid.services.ha = {
    enable = lib.mkEnableOption "Enable HA";

    z2m_device = lib.mkOption {
      type = types.str;
    };

    matter = {
      enable = lib.mkEnableOption "Enable OTBR";
      device = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.zigbee2mqtt.after = [ "mosquitto.service" ];
    systemd.services."home-assistant".after = [ "mosquitto.service" ];

    networking.firewall.allowedTCPPorts = [
      5580 # matter-server
      8120 # z2m
      8082 # otbr
      # 8123 # hass
    ];

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

      openthread-border-router = lib.mkIf cfg.matter.enable {
        enable = true;

        backboneInterface = "end0"; # TODO: ...
        logLevel = "warning"; # TODO: ...

        web = {
          enable = true;
          listenAddress = "::";
          listenPort = 8082;
        };

        radio = {
          device = cfg.matter.device;
          baudRate = 460800;
          flowControl = false;
        };
      };

      matter-server = {
        enable = true;
        extraArgs = [ ];
        logLevel = "info";
        port = 5580;
        openFirewall = true;
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
          "matter"
          "thread"
          "otbr"
          "apple_tv"
        ];

        config = {
          "automation ui" = "!include automations.yaml";
          "scene ui" = "!include scenes.yaml";
          "script ui" = "!include scripts.yaml";

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
