{ inputs, mode, config, secrets, ... }:
{
  imports = [
    inputs.home-manager."${if mode == "Darwin" then "darwinModules" else "nixosModules"}".home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs secrets;

      device = config.device;
      mode = "${mode}-HM";
    };

    users.rubikoid = { inputs, ... }: {
      imports = [
        ./../base-user.nix # ok ugly and what you can do with it... 
        inputs.self.users.rubikoid
        inputs.self.defaultModules.options
        {
          user = "rubikoid";
        }
      ];
    };
  };
}
