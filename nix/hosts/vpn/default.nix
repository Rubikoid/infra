{ pkgs, config, inputs, lib, ... }:

{
  imports = with inputs.self.systemModules; [
    ./hardware-configuration.nix
    ./wg.nix
    yggdrasil
    compact
  ];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = false;

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOXNeouqZX2g3lYGgI+R9kGOBGPhV+cOvXOHPxKRygKl rubikoid@rubikoid.ru''
  ];

  services.yggdrasil = {
    openMulticastPort = false;

    settings = {
      Listen = [
        "tls://0.0.0.0:51342"
      ];

      MulticastInterfaces = lib.mkForce [ ];
    };
  };

  sops.secrets.rubi_pw = {
    sopsFile = ../../secrets + "/${config.device}/secrets.yaml";
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

  networking.firewall.interfaces = {
    home.allowedTCPPorts = [ 1337 ];
    ygg.allowedTCPPorts = [ 1337 ];
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

  systemd.services.dante.after = [ "yggdrasil.service" ]

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
