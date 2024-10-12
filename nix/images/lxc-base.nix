{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  hostname = "lxc-generic";
  system = lib.readSystem hostname;
in
inputs.nixos-generators.nixosGenerate {
  inherit pkgs system;
  modules =
    (with inputs.self.systemModules; [
      compact

      ca_rubikoid

      openssh
      openssh-root-key

      in-proxmox-lxc
    ])
    ++ [
      (import ../modules/default/nix.nix)
      (import ../modules/default/options.nix)
      (import ../modules/base-system.nix)
      (import ../modules/base-system-linux.nix)
      {
        system-arch-name = system;
        device = hostname;
        isWSL = false;
      }
      {
        environment.systemPackages = with pkgs; [
          tmux
          htop
          rsync
        ];

        system.stateVersion = "24.05";
      }
    ];
  format = "proxmox-lxc";
  specialArgs = {
    inherit inputs;

    secretsModule = inputs.self.secrets.nixosModules.default;
    secrets = inputs.self.secrets.secretsBuilder hostname;

    mode = "NixOS";
  };
}
