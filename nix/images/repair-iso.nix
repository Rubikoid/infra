{ inputs, lib, pkgs, ... }:
let
  hostname = "kubic";
  system = lib.r.readSystem hostname;
in
inputs.nixos-generators.nixosGenerate {
  inherit pkgs system;
  modules = (with lib.r.modules.system; [
    ca_rubikoid

    ntfs
    zfs

    openssh
    openssh-root-key

    gigabyte-fans

    smartd
  ]) ++
  [
    (import ../modules/default/options.nix)
    (import ../modules/base-system.nix)
    (import ../modules/base-system-linux.nix)
    {
      system-arch-name = system;
      device = hostname;
      isWSL = false;
    }
    {
      nix = {
        package = pkgs.nix;
        registry = {
          nixpkgs.flake = inputs.nixpkgs;
          n.flake = inputs.nixpkgs;
        };
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
            "repl-flake"
          ];
        };
      };
    }
    {
      boot.supportedFilesystems = [ "exfat" "f2fs" "fat8" "fat16" "fat32" ];

      networking.hostId = (inputs.self.secrets.secretsBuilder hostname).zfsHostId; # need by zfs
      # systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
      services.zfs.autoScrub.enable = false;

      # auto detect type of disk
      # disable auto offline tests (they are slow and we don't need them now)
      # check health
      services.smartd.defaults.monitored = "-d auto -o off -H -l selftest -l selfteststs -l error -l xerror -f -t -C 197 -U 198";

      environment.systemPackages = with pkgs; [
        tmux
        btop
        htop
        rsync
        lm_sensors
      ];

      system.stateVersion = "23.11";
    }
  ];
  format = "install-iso";
  specialArgs = {
    inherit inputs;

    secretsModule = inputs.self.secrets.nixosModules.default;
    secrets = inputs.self.secrets.secretsBuilder hostname;

    mode = "NixOS";
  };
}
