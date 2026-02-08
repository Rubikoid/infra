{
  pkgs,
  config,
  secrets,
  inputs,
  lib,
  utils,
  ...
}:

{
  imports = lib.lists.flatten (
    with lib.r.modules.system;
    [
      other.home-assistant-rpi
    ]
  );

  boot = {
    tmp.useTmpfs = true;
  };

  services.home-assistant.config = {
    homeassistant = {
      allowlist_external_dirs = [
        "/data/hass"
      ];
    };

    history = { };

    recorder = {
      db_url = "sqlite:////data/hass/hm_log.sqlite3";
      # db_url = "sqlite:////hm_log.sqlite3";
      purge_keep_days = 365;
    };

    energy = { };
    logbook = { };
    mobile_app = { };

    mobile_app = { };
  };

  rubikoid = {
    services.ha = {
      z2m_device = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_ac4a56e4af14ef11817e6fb8bf9df066-if00-port0";

      matter = {
        enable = true;
        device = "/dev/serial/by-id/usb-Itead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_V2_b2c27742ff4eef119a9d50b3174bec31-if00-port0";
      };
    };
  };

  hardware = {
    deviceTree.filter = "bcm2711-rpi-cm4.dtb";

    raspberry-pi."4" = {
      dwc2 = {
        enable = true;
        dr_mode = "host";
      };

      xhci.enable = true;
    };
  };

  fileSystems."/data" = {
    device = "/dev/disk/by-id/nvme-SAMSUNG_MZ9LQ128HBHQ-000H1_S5MJNF0R500898-part1";
    fsType = "ext4";
    options = [
      "defaults"
      "nofail"
      "x-systemd.device-timeout=0"
    ];
  };

  networking.useDHCP = true;

  system.stateVersion = "24.11"; # Did you read the comment?
}
