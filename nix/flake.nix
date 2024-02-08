{
  description = "NixOS config for entire life...";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-old.url = "nixpkgs/23.05";
    # nixpkgs-overleaf.url = "github:JulienMalka/nixpkgs/overleaf";
    # nixpkgs-pdns-admin.url = "github:Flakebi/nixpkgs/powerdns-admin";

    # home-manager upstream
    home-manager = {
      # url = github:nix-community/home-manager/release-23.05;
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops
    sops-nix = {
      url = "github:Mic92/sops-nix/2f375ed8702b0d8ee2430885059d5e7975e38f78";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-old";
    };

    # GUI things. WM, plugins
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    # and launcher
    anyrun = {
      url = "github:Kirottu/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ygg-map = {
      url = "github:rubikoid/yggdrasil-map-ng/380b5446fb79ab3a1e06b1b798712915ecf0af6b";
      # url = "git+file:///root/ygg-map";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-dns = {
      url = "github:Janik-Haag/nixos-dns";
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
            allowUnfree = true;
            permittedInsecurePackages = [ ];
            # TODO: make it better
            allowUnfreePredicate = (pkg: builtins.elem (nixpkgs.lib.getName pkg)
              [
                "code"
                "obsidian"
                "nvidia-persistenced"
                "nvidia-settings"
                "nvidia-x11"
                "nvidia-x11-545.29.06-6.1.63"
                "cudatoolkit"
                "vmware-workstation-17.0.2"
              ]);
          };
        };

      secrets = import ../secrets inputs;
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
          mkHost = hostname:
            let
              # system arch readen from <hostname>/system OR x86_64
              system =
                if
                  builtins.pathExists (./hosts + "/${hostname}/system")
                then
                  removeSuffix "\n" (builtins.readFile (./hosts + "/${hostname}/system"))
                else
                  "x86_64-linux";

              # nixpkgs platform depended
              pkgs = pkgsFor system;
            in
            nixosSystem {
              inherit system;
              modules = __attrValues self.defaultModules ++ [
                (import ./modules/base-system.nix)
                (import (./hosts + "/${hostname}"))
                { nixpkgs.pkgs = pkgs; }
                { device = hostname; }
                # { deviceSecrets = ./secrets + "/${hostname}/"; }
              ];
              specialArgs = {
                inherit inputs;

                secretsModule = secrets.nixosModules.default;
                secrets = secrets.secretsBuilder hostname;
              };
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
                # { userSecrets = ./secrets + "/${name}/"; }
              ];
              extraSpecialArgs = { inherit inputs; };
            };
        in
        genAttrs users mkUser;

      lib = import ./lib.nix nixpkgs.lib;
    };
}
