{
  lib,
  config,
  secrets,
  pkgs,
  inputs,
  ...
}:

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
        inherit (inputs.self) extraSpecialArgsGenerator forEachVMHostUnfiltred;
        forEachEnabledVMHost = forEachVMHostUnfiltred (source: hostname: builtins.elem hostname cfg.vms);
        result = forEachEnabledVMHost (
          (
            { info, ... }@args:
            lib.filterAttrs (n: v: n != "lib") (
              lib.r.mkSystemOnlyConfig args {
                specialArgs = extraSpecialArgsGenerator info;
              }
            )
          )
        );
      in
      result;
    # (hostname: {
    #   # TODO: proper pkgs... i think...
    #   inherit pkgs;
    #   config = {
    #     imports = builtins.attrValues lib.r.modules.default ++ [
    #       ../base-system.nix
    #       ../base-system-vm.nix
    #       ../base-system-linux.nix
    #       (../../vms + "/${hostname}")
    #     ];

    #     system-arch-name = "x86_64-linux";
    #     device = hostname;
    #     isWSL = false;
    #   };
    #   specialArgs = {
    #     inherit inputs;

    #     secretsModule = inputs.self.secrets.nixosModules.default;
    #     secrets = inputs.self.secrets.secretsBuilder hostname;
    #     mode = "NixOS";
    #   };
    # });
  };
}
