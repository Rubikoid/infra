{
  description = "NixOS config for entire life...";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixpkgs-old.url = "github:NixOS/nixpkgs/bd645e8668ec6612439a9ee7e71f7eac4099d4f6";
    nixpkgs-old-basedpyright.url = "github:NixOS/nixpkgs/48596fb13bc91bdc1b44bcdd6b0f87f0467d34c0";
    nixpkgs-old-stable.url = "github:NixOS/nixpkgs/nixos-23.11";

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

    nix-darwin = {
      # url = "github:rubikoid/nix-darwin/rubikoid/offline-flag";
      # url = "/Users/rubikoid/projects/git/nix-darwin";
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-wsl = {
      url = "github:nix-community/NixOS-WSL/2405.5.4";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    microvm = {
      url = "github:astro/microvm.nix/a808af7775f508a2afedd1e4940a382fe1194f21"; # master as of 15-07-2024
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, nix-wsl, microvm, ... } @ inputs:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" "aarch64-linux" ];

      # another idk magic from @balsoft flake.nix...
      _pkgsFor = nixpkgs: system:
        import nixpkgs {
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

      pkgsFor = _pkgsFor inputs.nixpkgs;

      lib = import ./lib.nix nixpkgs nixpkgs.lib;
      secrets = import ../secrets inputs;

      forEachSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        inherit system;
        pkgs = pkgsFor system;
      });

      raw_hosts = builtins.attrNames (builtins.readDir ./hosts);
      raw_vms = builtins.attrNames (builtins.readDir ./vms);

      forEachPkgsBuilder = source: filter: f: nixpkgs.lib.genAttrs (builtins.filter filter source) (hostname: f rec {
        inherit hostname;
        system = lib.readSystem hostname;
        pkgs = pkgsFor system;
      });

      forEachHost = forEachPkgsBuilder raw_hosts;
      forEachVM = forEachPkgsBuilder raw_vms (hostname: true);
      forEachHostSimple = forEachHost (hostname: true);
    in
    {
      inherit lib secrets;
      inherit raw_vms;

      defaultModules = builtins.listToAttrs (lib.findModules ./modules/default);
      systemModules = builtins.listToAttrs (lib.findModules ./modules/system);
      darwinModules = builtins.listToAttrs (lib.findModules ./modules/darwin);
      userModules = builtins.listToAttrs (lib.findModules ./modules/user);
      users = builtins.listToAttrs (lib.findModules ./users);
      overlay = import ./overlay.nix inputs;

      nixosConfigurations =
        let
          genericNixOSConfig = { system, hostname, pkgs }: {
            inherit system;
            modules = builtins.attrValues self.defaultModules ++ [
              (import ./modules/base-system.nix)
              (import ./modules/base-system-linux.nix)
              { nixpkgs.pkgs = pkgs; }
              {
                system-arch-name = system;
                device = hostname;
                isWSL = lib.isWSLFilter hostname;
              }
              (if (lib.isWSLFilter hostname) then nix-wsl.nixosModules.default else { })
              # (if (lib.isWSLFilter hostname) then import ./fixes/wsl else { })
            ];
            specialArgs = {
              inherit inputs;

              secretsModule = secrets.nixosModules.default;
              secrets = secrets.secretsBuilder hostname;
            };
          };

          mkSystem = { ... } @ inp: extra: nixpkgs.lib.nixosSystem (lib.recursiveMerge [
            (genericNixOSConfig inp)
            extra
          ]);
        in
        (forEachHostSimple ({ system, hostname, pkgs } @ inp: mkSystem inp {
          modules = [
            (import (./hosts + "/${hostname}"))
          ];
          specialArgs = {
            mode = "NixOS";
          };
        }))
        //
        forEachVM ({ system, hostname, pkgs } @ inp: mkSystem inp {
          modules = [
            microvm.nixosModules.microvm
            (import ./modules/base-system-vm.nix)
            (import (./vms + "/${hostname}"))
          ];
          specialArgs = {
            mode = "NixOS";
          };
        });

      darwinConfigurations = forEachHost lib.isDarwinFilter ({ system, hostname, pkgs }: nix-darwin.lib.darwinSystem {
        inherit system;
        modules = builtins.attrValues self.defaultModules ++ [
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
      });

      devShells = forEachSystem ({ system, pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            nil
            nixpkgs-fmt
            sops
            # nixfmt-rfc-style
          ];
        };

        yark = pkgs.mkShell {
          packages = with pkgs; [
            python312Packages.yark
            ffmpeg
          ];

          shellHook = ''
            export ALL_PROXY="${secrets.hostLessSecrets.proxy}"
          '';
        };
      });

      packages = forEachSystem ({ system, pkgs }: {
        kubic-repair = import ./repair-iso.nix { inherit inputs lib system pkgs; };
        glitch-soc-source = pkgs.callPackage ./pkgs/mastodon/source.nix { };
        glitch-soc = pkgs.callPackage ./pkgs/mastodon/default.nix { };
      });
    };
}
