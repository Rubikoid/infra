{
  description = "NixOS config for entire life...";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixpkgs-old.url = "github:NixOS/nixpkgs/bd645e8668ec6612439a9ee7e71f7eac4099d4f6";
    nixpkgs-old-stable.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-old-stable-darwin.url = "github:NixOS/nixpkgs/nixpkgs-23.11-darwin";

    # home-manager upstream
    home-manager = {
      # url = github:nix-community/home-manager/release-23.05;
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops
    sops-nix = {
      url = "github:Mic92/sops-nix/0dc50257c00ee3c65fef3a255f6564cfbfe6eb7f";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-old-stable";
    };

    # sops but for darwin
    sops-nix-darwin = {
      url = "github:Kloenk/sops-nix/darwin";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-old-stable";
    };

    # GUI things. WM, plugins
    # hyprland = {
    #   url = "github:hyprwm/Hyprland";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # hyprland-plugins = {
    #   url = "github:hyprwm/hyprland-plugins";
    #   inputs.hyprland.follows = "hyprland";
    # };
    # and launcher
    anyrun = {
      url = "github:Kirottu/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ygg-map = {
      url = "github:rubikoid/yggdrasil-map-ng/e3e0203eb4c2715668d620e0778761a605e66178";
      # url = "git+file:///root/ygg-map";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-dns = {
      url = "github:Janik-Haag/nixos-dns";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-darwin.url = "github:LnL7/nix-darwin/36524adc31566655f2f4d55ad6b875fb5c1a4083";
    nix-darwin.url = "github:rubikoid/nix-darwin/rubikoid/offline-flag";
    # nix-darwin.url = "/Users/rubikoid/projects/git/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-wsl.url = "github:nix-community/NixOS-WSL/aef95bdb6800a3a2af7aa7083d6df03067da6592";
    nix-wsl.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, nix-wsl, ... } @ inputs:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" "aarch64-linux" ];

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

      lib = import ./lib.nix nixpkgs nixpkgs.lib;
      secrets = import ../secrets inputs;
    in
    {
      inherit lib secrets;

      defaultModules = builtins.listToAttrs (lib.findModules ./modules/default);
      systemModules = builtins.listToAttrs (lib.findModules ./modules/system);
      darwinModules = builtins.listToAttrs (lib.findModules ./modules/darwin);
      userModules = builtins.listToAttrs (lib.findModules ./modules/user);
      users = builtins.listToAttrs (lib.findModules ./users);
      overlay = import ./overlay.nix inputs;

      # idk another magic from @balsoft flake.nix... (but somethere explained)
      nixosConfigurations = with nixpkgs.lib;
        let
          # get hosts list from ./hosts directory
          hosts = builtins.attrNames (builtins.readDir ./hosts);

          # define function for defining each host
          mkHost = hostname:
            let
              system = lib.readSystem hostname;
              pkgs = pkgsFor system;
            in
            nixosSystem {
              inherit system;
              modules = __attrValues self.defaultModules ++ [
                {
                  system-arch-name = system;
                  device = hostname;
                  isWSL = lib.isWSLFilter hostname;
                }
                (import ./modules/base-system.nix)
                (import ./modules/base-system-linux.nix)
                (import (./hosts + "/${hostname}"))
                { nixpkgs.pkgs = pkgs; }
                (if (lib.isWSLFilter hostname) then nix-wsl.nixosModules.default else { })
                (if (lib.isWSLFilter hostname) then import ./fixes/wsl else { })
              ];
              specialArgs = {
                inherit inputs;

                secretsModule = secrets.nixosModules.default;
                secrets = secrets.secretsBuilder hostname;

                mode = "NixOS";
              };
            };
        in
        genAttrs hosts mkHost;

      darwinConfigurations = with nixpkgs.lib;
        let
          hosts = builtins.filter lib.isDarwinFilter (builtins.attrNames (builtins.readDir ./hosts));

          mkDarwinHost = hostname:
            let
              system = lib.readSystem hostname;
              pkgs = pkgsFor system;
            in
            nix-darwin.lib.darwinSystem {
              inherit system;
              modules = __attrValues self.defaultModules ++ [
                (import ./modules/base-system.nix)
                (import ./modules/base-system-darwin.nix)
                (import (./hosts + "/${hostname}"))
                { nixpkgs.pkgs = pkgs; }
                {
                  system-arch-name = system;
                  device = hostname;
                  isDarwin = true;
                }
              ];
              specialArgs = {
                inherit inputs;

                secretsModule = secrets.darwinModules.default;
                secrets = secrets.secretsBuilder hostname;

                mode = "Darwin";
              };
            };
        in
        genAttrs hosts mkDarwinHost;

      # homeConfigurations = with nixpkgs.lib;
      #   let
      #     # get hosts list from ./hosts directory
      #     users = builtins.attrNames (builtins.readDir ./users);

      #     mkUser = name:
      #       let
      #         system = "x86_64-linux"; # TODO: make this properly
      #         pkgs = pkgsFor system;
      #       in
      #       home-manager.lib.homeManagerConfiguration {
      #         pkgs = pkgs;
      #         modules = __attrValues self.defaultModules ++ [
      #           (import ./modules/base-user.nix)
      #           (import (./users + "/${name}"))
      #           # {
      #           #   nixpkgs.overlays = [ self.overlay ];
      #           # }
      #           { user = name; }
      #           # { userSecrets = ./secrets + "/${name}/"; }
      #         ];
      #         extraSpecialArgs = {
      #           inherit inputs;

      #           mode = "home-manager";
      #         };
      #       };
      #   in
      #   genAttrs users mkUser;

      devShell = with nixpkgs.lib;
        let
          genShell = system:
            let
              pkgs = pkgsFor system;
            in
            pkgs.mkShell {
              packages = with pkgs; [
                nil
                nixpkgs-fmt
                sops
              ];
            };
        in
        genAttrs supportedSystems genShell;
    };
}
