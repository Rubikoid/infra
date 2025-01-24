{ config, secrets, lib, ... }:
let
  configBuilder =
    nodename: extra:
    lib.r.recursiveMerge [
      {
        # how to connect
        protocol = "ssh-ng";
        sshUser = "nix-builder";
        hostName = "${nodename}.nodes.${secrets.dns.private}";
        sshKey = config.sops.secrets."nix-builder-private-key".path;

        # describing machine
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        # system = "x86_64-linux";

        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
        mandatoryFeatures = [ ];
      }
      extra
    ];
in
{
  sops.secrets."nix-builder-private-key" = {
    mode = "0400";
    sopsFile = secrets.deviceSecrets + "/secrets.yaml";
    owner = "rubikoid"; # TODO: eww...
  };

  nix = {
    extraOptions = "builders-use-substitutes = true"; # pull packages through builder
    distributedBuilds = true; # enable distributed builds
    buildMachines = [
      (configBuilder "kubic" {
        maxJobs = 8; # kubic has 8/16 CPU, so...
        speedFactor = 2;
        publicHostKey = secrets.ssh.public.kubic;
      })
      (lib.mkIf (config.device != "r7-wsl") (
        configBuilder "wsl.r7" {
          maxJobs = 4; # r7 has 8/16 CPU, so...
          speedFactor = 1;
          publicHostKey = secrets.ssh.public.r7wsl;
        }
      ))
    ];
  };
}
