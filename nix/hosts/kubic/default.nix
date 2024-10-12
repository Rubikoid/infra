{ pkgs, config, secrets, inputs, lib, ... }:

{
  imports = with inputs.self.systemModules; [
    ./hardware-configuration.nix

    locale
    yggdrasil
    zsh
    zsh-config
    wg-client
    dns
    http

    # ca
    ca_rubikoid

    # security
    openssh
    openssh-root-key

    # fs
    ntfs
    zfs

    # hardware
    gigabyte-fans

    # services
    caddy
    memos
    powerdns
    minio
    akkoma
    mastodon
    ygg-map
    actual
    harmonia
    vaultwarden
    vikunja
    py-kms
    # overleaf-docker
    # overleaf
    # cocalc
    betula
    # owntracks
    clamav
    dawarich
    xandikos
    # tubearchivist
    ## garden
    immich
    paperless
    garden
    smb
    ## media
    arr
    jellyfin
    ## monitoring
    grafana
    grafana-agent
    ## syncthing
    ss

    # other
    remote-build-host

    # ./vm.nix

    # containers
    # yatb-kube

    # wtf
    macvtap
    microvm
  ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };

    initrd.kernelModules = [ ];
  };

  boot.zfs.extraPools = [
    "data"
    "backup-drive"
  ];

  networking.hostId = secrets.zfsHostId; # need by zfs

  environment.systemPackages = with pkgs; [
    nix-output-monitor
    vim-full
    tmux
    iotop
    htop
    wget
    curl
    tcpdump
    lm_sensors
    smartmontools
    pciutils # lspci
    usbutils # lsusb
    nix-index # nix-lookup for binary
    ldns # dns help
    moreutils
    jq
    # nvidia-docker
    helix
  ];

  rubikoid.microvm.vms = [
    # "yatb-kube-master"
  ];
  microvm.autostart = lib.mkForce [ ];

  hardware = {
    # Enable OpenGL
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      # Modesetting is required.
      modesetting.enable = true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      powerManagement.enable = false;
      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = false;

      open = false;

      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  virtualisation = {
    oci-containers.backend = "docker";

    docker = {
      enable = true;
      enableNvidia = true;

      # storageDriver = "zfs";
      # daemon.settings = {
      #   data-root = "/backup-drive/docker-data";
      # };
    };
  };

  hardware.fancontrol = {
    enable = true;

    config = ''
      INTERVAL=10
      DEVPATH=hwmon6=devices/platform/it87.2624 hwmon7=devices/pci0000:00/0000:00:18.3
      DEVNAME=hwmon6=it8689 hwmon7=k10temp
      FCTEMPS=hwmon6/pwm5=hwmon7/temp1_input hwmon6/pwm1=hwmon7/temp1_input
      FCFANS=hwmon6/pwm5=hwmon6/fan5_input hwmon6/pwm1=hwmon6/fan1_input
      MINTEMP=hwmon6/pwm5=30 hwmon6/pwm1=30
      MAXTEMP=hwmon6/pwm5=65 hwmon6/pwm1=65
      MINSTART=hwmon6/pwm5=150 hwmon6/pwm1=150
      MINSTOP=hwmon6/pwm5=0 hwmon6/pwm1=0
    '';
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_14;
    dataDir = "/backup-drive/data/psql//${config.services.postgresql.package.psqlSchema}";
  };

  networking.firewall.interfaces.home.allowedTCPPorts = [ 9008 9009 ];

  networking.hosts = {
    "${secrets.dns.vpn_ip}" = [ "vpn.rubikoid.ru" ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
