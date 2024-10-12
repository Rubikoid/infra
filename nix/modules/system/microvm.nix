{ lib, config, secrets, pkgs, inputs, ... }:

let
  types = lib.types;
  cfg = config.rubikoid.microvm;
in
{
  imports = [
    inputs.microvm.nixosModules.host
  ];

  options.rubikoid.microvm = {
    vms = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config = {
    microvm.vms =
      let
        enabledVMFilter = hostname: builtins.elem hostname cfg.vms;
      in
      lib.genAttrs (builtins.filter enabledVMFilter inputs.self.raw_vms) (hostname: {
        # TODO: proper pkgs... i think...
        inherit pkgs;
        config = {
          imports = builtins.attrValues inputs.self.defaultModules ++ [
            ../base-system.nix
            ../base-system-vm.nix
            ../base-system-linux.nix
            (../../vms + "/${hostname}")
          ];

          system-arch-name = "x86_64-linux";
          device = hostname;
          isWSL = false;
        };
        specialArgs = {
          inherit inputs;

          secretsModule = inputs.self.secrets.nixosModules.default;
          secrets = inputs.self.secrets.secretsBuilder hostname;
          mode = "NixOS";
        };
      });
  };
}
