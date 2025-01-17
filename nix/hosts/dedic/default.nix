{
  pkgs,
  config,
  inputs,
  secrets,
  lib,
  ...
}:

{
  imports = lib.lists.flatten (
    with lib.r.modules.system;
    [
      ./hardware-configuration.nix

      # local
      ./docker.nix
      ./wg.nix

      compact
      locale
      yggdrasil
      zsh
      wg-client

      (with other; [
        zsh-config
        in-proxmox-lxc
        split-dns
      ])

      ca.rubikoid

      (with security; [
        openssh
        openssh-root-key
      ])

      (with services; [
        step-ca
        budget-git
        caddy
        tg-bot-api
        # revolt
        owncast

        (with monitoring; [
          grafana-agent-ng
        ])
      ])
    ]
  );

  proxmoxLXC = {
    manageNetwork = false;
    privileged = false;
    manageHostName = true;
  };

  services.resolved.enable = false;
  networking.useHostResolvConf = lib.mkForce true;

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

    promExporters = {
      ping = true;
    };

  };

  environment.systemPackages = with pkgs; [
    htop
    dnsutils
    tcpdump
    nix-output-monitor
  ];


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
