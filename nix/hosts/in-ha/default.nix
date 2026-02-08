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

  # check: ?
  boot = {
    tmp.useTmpfs = true;
    kernelPackages = pkgs.linuxPackages_rpi4;
    initrd.availableKernelModules = [
      "usbhid"
      "usb_storage"
    ];

    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = lib.mkForce true;
    };

    kernel.sysctl = {
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
    };
  };
  hardware.enableRedistributableFirmware = true;

  nix = {
    settings.auto-optimise-store = true;
    # Free up to 1GiB whenever there is less than 100MiB left.
    extraOptions = ''
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
    '';
  };

  systemd.network = {
    enable = true;
    networks = {
      "10-ethernet" = {
        matchConfig.Name = "end0";
        networkConfig = {
          DHCP = "ipv4";
        };
        dhcpV4Config = {
          RouteMetric = 100;
        };
      };
      "20-wifi" = {
        matchConfig.Name = "wlan0";

        networkConfig = {
          DHCP = "ipv4";
        };

        dhcpV4Config = {
          RouteMetric = 600;
        };
      };
    };
  };

  networking = {
    useDHCP = false;
    useNetworkd = true;

    wireless = {
      enable = true;
      userControlled.enable = true;
      networks = {
        
      };
    };

  };

  rubikoid = {
    services.ha = {
      z2m_device = "/dev/serial/by-id/usb-ITEAD_SONOFF_Zigbee_3.0_USB_Dongle_Plus_V2_20221031155527-if00";
    };
  };

  services.home-assistant.config = {
    homeassistant = {
      allowlist_external_dirs = [
        "/data/hass"
      ];
    };

    # history = { };

    # recorder = {
    #   db_url = "sqlite:////data/hass/hm_log.sqlite3";
    #   # db_url = "sqlite:////hm_log.sqlite3";
    #   purge_keep_days = 365;
    # };

    # energy = { };
    # logbook = { };

    mobile_app = { };
  };

  environment.systemPackages = with pkgs; [

  ];

  hardware = {
    deviceTree.filter = "bcm2711-rpi-4-b.dtb";

    raspberry-pi."4" = {
      # dwc2 = {
      #   enable = true;
      #   dr_mode = "host";
      # };

      # xhci.enable = true;
    };
  };

  system.stateVersion = "24.11"; # Did you read the comment?
}
