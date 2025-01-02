{ config, pkgs, lib, inputs, ... }:
let
  minio = {
    secretKey = "asdasdasd";
    accessKey = "asdasdasd";
    # consoleAddress = ":9101";
    # listenAddress = ":9100";
  };
  registrySetup = pkgs.writeText "registries.yaml" (lib.generators.toYAML { } {
    mirrors."registry.local".endpoint = [ "http://192.168.1.44:5000/v2" ];
  });
in
{
  imports = with inputs.self.systemModules; [
    # general
    zsh
    zsh-config

    # ca
    ca_rubikoid

    # security
    openssh
    openssh-root-key

    # TODO: sort
    yggdrasil
  ];

  microvm = {
    # hypervisor = "cloud-hypervisor";

    vcpu = 4;
    mem = 8192;

    interfaces = [{
      type = "macvtap";
      id = "vm1"; # config.device;

      macvtap = {
        link = "enp6s0";
        mode = "bridge";
      };
      mac = "c2:8d:e5:a9:22:14";
    }];

    shares = [
      {
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
      }
      # {
      #   tag = "persist";
      #   source = "/yatb-kube/var-lib";
      #   mountPoint = "/var/lib";
      # }
      {
        tag = "persist-etc";
        source = "/yatb-kube/etc-rancher";
        mountPoint = "/etc/rancher";
      }
      {
        tag = "persist-etc-ssh";
        source = "/yatb-kube/etc-ssh";
        mountPoint = "/etc/ssh";
      }
      # {
      #   tag = "persist-etc-registries";
      #   source = "${registrySetup}";
      #   mountPoint = "/etc/rancher/k3s/registries.yaml";
      # }
    ];

    volumes = [{
      image = "/yatb-kube/data.img";
      label = "persistence";
      mountPoint = "/";
      size = 32000; # in mbytes...
    }];
  };

  fileSystems."/etc/ssh".neededForBoot = true;

  environment.etc."rancher/k3s/registries.yaml".source = registrySetup;
  # system.activationScripts.setup-registers.text = ''
  #   echo "wtf"
  #   mount | grep etc
  #   mkdir -p /etc/rancher/k3s
  #   cp ${registrySetup} /etc/rancher/k3s/registries.yaml
  #   echo "cped ${registrySetup} to /etc/..."
  # '';

  environment.systemPackages = with pkgs; [
    htop
    tmux
    tcpdump
    tshark
    k9s
  ];

  services.minio = {
    enable = true;
  } // minio;

  services.k3s = {
    enable = true;
    role = "server"; # force server...
    disableAgent = false;
    extraFlags = builtins.concatStringsSep " " [
      "--tls-san='yatb-kube-master.nodes.internal.rubikoid.ru'"
      "--cluster-cidr=10.42.0.0/16,2001:cafe:42::/56"
      "--service-cidr=10.43.0.0/16,2001:cafe:43::/112"
      "--node-ip=192.168.1.44,202:ae5d:1f6b:bac7:2b4e:304c:ef7:47ca"
      "--node-external-ip=192.168.1.44,202:ae5d:1f6b:bac7:2b4e:304c:ef7:47ca"
      # "--kubelet-arg='node-ip=0.0.0.0'"
      "--flannel-ipv6-masq"
      "--flannel-external-ip"
    ];
    # "--flannel-backend=wireguard-native --debug -v 6 --alsologtostderr --log /tmp/wtf.txt";
  };

  services.dockerRegistry = {
    enable = true;

    extraConfig = { };

    listenAddress = "0.0.0.0";
    port = 5000;
    openFirewall = true;
  };

  networking.firewall.allowedTCPPorts = [
    6443 # k8s api
    8001 # idk
    9000 # minio
    9001 # minio ui
    # 5000 # docker registry
  ];
  networking.firewall.allowedTCPPortRanges = [{ from = 30000; to = 32767; }];

  # users.users.root.password = "";
  services.getty.autologinUser = "root";
  system.stateVersion = "24.05";
}
