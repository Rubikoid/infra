{ config, secrets, ... }:
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
      {
        # how to connect
        protocol = "ssh-ng";
        sshUser = "nix-builder";
        hostName = "kubic.${secrets.dns.private}";
        sshKey = config.sops.secrets."nix-builder-private-key".path;
        publicHostKey = secrets.ssh.public.kubic;

        # describing machine
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];
        # system = "x86_64-linux";
        maxJobs = 8; # kubic has 8/16 CPU, so...
        speedFactor = 2;
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        mandatoryFeatures = [ ];
      }
    ];
  };
}
