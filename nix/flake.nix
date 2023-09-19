{
  description = "NixOS config for entire life...";

  # nixConfig = {
  #   extra-substituters = [
  #     "https://cache.nixos.org"
  #   ];
  #   trusted-public-keys = [
  #     "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  #   ];
  # };

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    # home-manager upstream
    home-manager = {
      # url = github:nix-community/home-manager/release-22.11;
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };


    # GUI things. WM, plugins
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins.url = "github:hyprwm/hyprland-plugins";
    # and launcher
    anyrun = {
      url = "github:Kirottu/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };



  outputs = { self, nixpkgs, ... } @ inputs:
    let
      # idk magic from @balsoft flake.nix...
      findModules = dir:
        builtins.concatLists (builtins.attrValues (builtins.mapAttrs
          (name: type:
            if type == "regular" then [{
              name = builtins.elemAt (builtins.match "(.*)\\.nix" name) 0;
              value = dir + "/${name}";
            }] else if (builtins.readDir (dir + "/${name}"))
              ? "default.nix" then [{
              inherit name;
              value = dir + "/${name}";
            }] else
              findModules (dir + "/${name}"))
          (builtins.readDir dir)));
      pkgsFor = system:
        import inputs.nixpkgs {
          overlays = [ self.overlay ];
          localSystem = { inherit system; };
          config = {
            permittedInsecurePackages = [ ];
            allowUnfreePredicate = (pkg: builtins.elem pkg.pname [ ]);
          };
        };
    in
    {
      defaultModules = builtins.listToAttrs (findModules ./modules/default);
      nixosModules = builtins.listToAttrs (findModules ./modules/system);
      homeModules = builtins.listToAttrs (findModules ./modules/user);
      overlay = import ./overlay.nix inputs;

      # idk another magic from @balsoft flake.nix... (but somethere explained)
      nixosConfigurations = with nixpkgs.lib;
        let
          # get hosts list from ./hosts directory
          hosts = builtins.attrNames (builtins.readDir ./hosts);

          # define function for defining each host
          mkHost = name:
            let
              # system arch readen from <host_name>/system OR x86_64
              system =
                if
                  builtins.pathExists (./hosts + "/${name}/system")
                then
                  builtins.readFile (./hosts + "/${name}/system")
                else
                  "x86_64-linux";

              # nixpkgs platform depended
              pkgs = pkgsFor system;
            in
            nixosSystem {
              inherit system;
              modules = __attrValues self.defaultModules ++ [
                # inputs.home-manager.nixosModules.home-manager
                (import (./hosts + "/${name}"))
                { nixpkgs.pkgs = pkgs; }
                { device = name; }
              ];
              specialArgs = { inherit inputs; };
            };
        in
        genAttrs hosts mkHost;
    };
}
