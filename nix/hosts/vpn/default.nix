{
  pkgs,
  config,
  inputs,
  secrets,
  lib,
  ...
}:

{
  imports = with lib.r.modules.system; [
    ./hardware-configuration.nix

    compact
    yggdrasil

    # ca
    ca_rubikoid

    # security
    openssh
    openssh-root-key

    # other
    split-dns

    # local
    ./wg.nix

    # services
    ## monitoring
    grafana-agent-ng
  ];

  boot = {
    tmp.cleanOnBoot = true;
    kernel.sysctl = {
      "net.ipv4.ip_forward" = true;
    };
  };

  zramSwap.enable = false;

  environment.systemPackages = with pkgs; [
    tcpdump
    nix-tree
  ];

  rubikoid.services.yggdrasil = {
    startMulticast = false;
    openPublic = true;
  };

  rubikoid.grafana-agent = {
    enable = true;

    mimir = {
      url = "http://mimir.${secrets.dns.private}/api/v1/push";
      tls_config = {
        ca = secrets.ca.rubikoid;
        insecure_skip_verify = true;
      };
    };
    loki = {
      url = "http://loki.${secrets.dns.private}/api/v1/push";
      tls_config = {
        ca = secrets.ca.rubikoid;
        insecure_skip_verify = true;
      };
    };
  };

  sops.secrets.rubi_pw = {
    sopsFile = secrets.deviceSecrets + "/secrets.yaml";
    neededForUsers = true;
  };

  users.users.rubi = {
    isNormalUser = true;
    createHome = false;
    useDefaultShell = false;
    expires = "2000-01-01"; # disable...
    group = "nogroup";

    hashedPasswordFile = config.sops.secrets.rubi_pw.path;
  };

  networking = {
    # networking.nameservers = [
    #   "1.1.1.1"
    #   "8.8.8.8"
    # ];

    firewall = {
      interfaces = {
        home.allowedTCPPorts = [ 1337 ];
        ygg.allowedTCPPorts = [ 1337 ];
      };
    };

    useDHCP = false;
    dhcpcd.IPv6rs = false;

    defaultGateway = {
      address = "10.0.0.1";
      interface = "ens3";
    };
  };

  services.udev.extraRules = ''
    ATTR{address}=="52:54:00:e0:ad:b8", NAME="ens3"
  '';

  services.dante = {
    enable = true;
    # debug: 2
    # log: connect disconnect ioop data tcpinfo
    config = ''
      internal: ygg port=1337
      internal: home port=1337
      external: ens3

      socksmethod: username

      client pass {
        from: 0/0 to: 0/0
        log: error
      }

      socks pass {
        from: 0/0 to: 0/0
        log: error
      }
    '';
  };

  systemd.services.dante.after = [ "yggdrasil.service" ];

  networking.resolvconf.extraConfig = ''
    unbound_conf=/etc/unbound-resolvconf.conf
  '';

  services.unbound.settings.include = [
    "/etc/unbound-resolvconf.conf"
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
