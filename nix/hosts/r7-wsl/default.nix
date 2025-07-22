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
      hm
      locale
      zsh
      yggdrasil

      dev.direnv
      ca.rubikoid
      users.rubikoid

      (with other; [
        remote-build
        remote-build-host
      ])

      (with security; [
        openssh
        openssh-root-key
      ])
    ]
  );

  # https://github.com/NixOS/nix/issues/13204#issuecomment-2903445729
  # WTF БЛЯДЬ ЭЭЛКО
  nix.package = lib.mkForce pkgs.lix;

  environment.systemPackages =
    with pkgs;
    [
      wget
    ]
    ++ [
      (pkgs.writeShellScriptBin "vscode-server-env-setup.sh" (
        builtins.readFile (./. + "/vscode-server-env-setup.sh")
      ))
    ];

  wsl = {
    enable = true;
    defaultUser = "rubikoid";
    nativeSystemd = true;
    useWindowsDriver = true;

    wslConf = {
      network.generateResolvConf = false;
    };

    interop.register = true;
  };

  # programs.nix-ld.enable = true;

  hardware.graphics.enable = lib.mkForce false;
  hardware.opengl.enable = lib.mkForce false;

  networking.firewall.allowedTCPPorts = [
    9999
    9900
  ];

  networking.nameservers = [
    secrets.dns.data.nodes.kubic.at.home
  ];

  # virtualisation.podman.enable = true;
  # users.users.rubikoid.extraGroups = [ "docker" ];

  # need to enable this, so user-part of systemd will start automatically
  users.users.rubikoid.linger = true;
  users.users.rubikoid.extraGroups = [ "ferretdb" ];

  services.ferretdb = {
    enable = true;
    settings = {
      FERRETDB_LISTEN_ADDR = ":27017";
      FERRETDB_TELEMETRY = "disable";
    };
  };

  services.etcd = {
    enable = false;
    openFirewall = true;

    initialClusterState = "new";
    initialClusterToken = "yatb-testing";

    listenClientUrls = [
      "http://127.0.0.1:2379"
    ];

    listenPeerUrls = [
      "http://[${secrets.yggdrasil.nodes.rubikoid.wsl-r7}]:2380"
    ];

    initialCluster = lib.mkForce [
      "r7-wsl=http://[${secrets.yggdrasil.nodes.rubikoid.wsl-r7}]:2380"
      "yatb-kube-master=http://[${secrets.yggdrasil.nodes.rubikoid.yatb-kube-master}]:2380"
    ];

    extraConf = {

    };
  };

  virtualisation = {
    oci-containers.backend = "docker";

    docker = {
      enable = true;

      daemon.settings.insecure-registries = [
        "192.168.10.44:5000"
      ];
      # storageDriver = "zfs";
      # daemon.settings = {
      #   data-root = "/backup-drive/docker-data";
      # };
    };
  };

  # services.openvpn.servers.wtf.config = ''
  #   dev tap0
  #   proto udp
  #   port 11337
  #   secret ${../vms/yatb-kube/master/static.key}

  #   ifconfig 10.10.1.1 255.255.255.240
  #   route 10.20.0.0 255.255.0.0 10.10.1.14

  #   cipher AES-256-CBC
  #   auth-nocache

  #   comp-lzo
  #   keepalive 10 60
  #   ping-timer-rem
  #   persist-key
  #   allow-compression yes
  # '';

  system.activationScripts.gitbash =
    let
      srcShell = config.users.users.rubikoid.shell;
      shell =
        let
          shellPath = utils.toShellPath srcShell;
          wrapper = pkgs.stdenvNoCC.mkDerivation {
            name = "wrapped-${lib.last (lib.splitString "/" (shellPath))}";
            buildCommand = ''
              mkdir -p $out
              cp ${config.system.build.nativeUtils}/bin/shell-wrapper $out/wrapper
              ln -s ${shellPath} $out/shell
            '';
          };
        in
        wrapper.outPath + "/wrapper";
    in
    lib.stringAfter [ "setupLogin" ] ''
      echo "setting up /bin/bash (fake ;) )..."
      ln -sf ${shell} /bin/bash
    '';
  #  ln -sf ${pkgs.git}/bin/git /bin/git

  system.stateVersion = "24.05"; # Did you read the comment?
}
