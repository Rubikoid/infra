{ pkgs, config, inputs, secrets, lib, ... }:

{
  imports = with inputs.self.systemModules; [
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
    grafana-agent-simple
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

  networking.firewall = {
    interfaces = {
      home.allowedTCPPorts = [ 1337 ];
      ygg.allowedTCPPorts = [ 1337 ];
    };
  };

  services.dante = {
    enable = true;
    config = ''
      internal: ygg port=1337
      internal: home port=1337
      external: ens1

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
