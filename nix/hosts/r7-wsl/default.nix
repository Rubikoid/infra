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

  services.ferretdb = {
    enable = true;
    settings = {
      FERRETDB_LISTEN_ADDR = ":27017";
      FERRETDB_TELEMETRY = "disabled";
    };
  };

  services.etcd = {
    enable = true;
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

      # storageDriver = "zfs";
      # daemon.settings = {
      #   data-root = "/backup-drive/docker-data";
      # };
    };
  };

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
