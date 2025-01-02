{
  inputs,
  mode,
  config,
  secrets,
  lib,
  ...
}:
{
  imports = [
    inputs.home-manager."${if mode == "Darwin" then "darwinModules" else "nixosModules"}".home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs secrets;
      inherit (config) device;

      mode = "${mode}-HM";
    };

    users.rubikoid =
      { inputs, ... }:
      {
        imports = [
          {
            user = "rubikoid";
          }
          lib.r.modules.base.user # not ugly anymore!
          inputs.self.users.rubikoid
          lib.r.modules.default.options
        ];
      };
  };
}
