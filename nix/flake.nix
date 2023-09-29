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
      # url = github:nix-community/home-manager/release-23.05;
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

  outputs = { self, nixpkgs, home-manager, ... } @ inputs:
    let
      # idk magic from @balsoft flake.nix...
      # some function for <dir: path>
      findModules = dir:
        # magic
        builtins.concatLists (
          # magic
          builtins.attrValues (
            # apply first function to every elem of readdir
            builtins.mapAttrs
              (
                name: # filename
                type: # filetype: regular, directory, symlink, unknown

                # if just a simple file - remove .nix and add it to path
                if type == "regular" then
                  if (builtins.match "(.*)\\.nix" name) != null then [{
                    # but check, is it really .nix file...
                    name = builtins.elemAt (builtins.match "(.*)\\.nix" name) 0;
                    value = dir + "/${name}";
                  }]
                  else [ ] # ~~i don't knew why it red...~~ because it is todo tree parsed

                # if it directory
                else if type == "directory" then
                  if (builtins.readDir (dir + "/${name}")) ? "default.nix" then [{
                    # if contains default.nix - load it
                    inherit name;
                    value = dir + "/${name}";
                  }]
                  else
                  # else just recursive load
                    findModules (dir + "/${name}")
                else [ ] # ~~i don't knew why it red...~~ because it is todo tree parsed
              )
              (builtins.readDir dir)
          )
        );

      # another idk magic from @balsoft flake.nix...
      pkgsFor = system:
        import inputs.nixpkgs {
          overlays = [ self.overlay ];
          localSystem = { inherit system; };
          config = {
            permittedInsecurePackages = [ ];
            # TODO: make it better
            allowUnfreePredicate = (pkg: builtins.elem pkg.pname [
              "code"
              "obsidian"
            ]);
          };
        };
    in
    {
      defaultModules = builtins.listToAttrs (findModules ./modules/default);
      systemModules = builtins.listToAttrs (findModules ./modules/system);
      userModules = builtins.listToAttrs (findModules ./modules/user);
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
                (import ./modules/base-system.nix)
                (import (./hosts + "/${name}"))
                { nixpkgs.pkgs = pkgs; }
                { device = name; }
                { deviceSecrets = ./secrets + "/${name}/"; }
              ];
              specialArgs = { inherit inputs; };
            };
        in
        genAttrs hosts mkHost;

      homeConfigurations = with nixpkgs.lib;
        let
          # get hosts list from ./hosts directory
          users = builtins.attrNames (builtins.readDir ./users);

          mkUser = name:
            let
              system = "x86_64-linux"; # TODO: make this properly
              pkgs = pkgsFor system;
            in
            home-manager.lib.homeManagerConfiguration {
              pkgs = pkgs;
              modules = __attrValues self.defaultModules ++ [
                (import ./modules/base-user.nix)
                (import (./users + "/${name}"))
                # {
                #   nixpkgs.overlays = [ self.overlay ];
                # }
                { user = name; }
                { userSecrets = ./secrets + "/${name}/"; }
              ];
              extraSpecialArgs = { inherit inputs; };
            };
        in
        genAttrs users mkUser;
    };
}
