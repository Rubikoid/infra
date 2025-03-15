{
  description = "NixOS config for entire life...";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-php.url = "github:NixOS/nixpkgs/nixos-20.09";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";

    nixpkgs-syncthing.url = "github:NixOS/nixpkgs/78e43c3df1efe30d7d2a5d6479587574ce774bd3";

    base = {
      # url = "path:./base";
      url = "github:rubikoid/nix-base";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };

    # sops but for darwin
    sops-nix-darwin = {
      url = "github:Kloenk/sops-nix/darwin";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };

    # ygg-map = {
    #   url = "github:rubikoid/yggdrasil-map-ng/e3e0203eb4c2715668d620e0778761a605e66178";
    #   # url = "git+file:///root/ygg-map";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    nixos-dns = {
      url = "github:Janik-Haag/nixos-dns/c4f734d771038db15700a61a8703d0da5f993b3a";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      # url = "github:rubikoid/nix-darwin/rubikoid/offline-flag";
      # url = "/Users/rubikoid/projects/git/nix-darwin";
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-wsl = {
      url = "github:nix-community/NixOS-WSL/dee4425dcee3149475ead0cb6a616b8a028c5888"; # master as of 04.01.2025
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

    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs.nixpkgs-unstable.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      base,
      home-manager,
      nix-darwin,
      nix-wsl,
      microvm,
      nixos-dns,
      nixpkgs-master,
      ...
    }@inputs:
    let
      lib = base.lib.r.extender base.lib (
        { lib, prev, r, prevr, ... }:
        {
          modules = r.recursiveMerge [
            prevr.modules
            (r.findModulesV2 ./modules)
          ];

          overlays = [
            (import ./overlay.nix inputs)
            (import ./pkgs.nix inputs)
          ];

          inherit (r.nixInit nixpkgs) pkgsFor forEachSystem mkSystem;
        }
      );

      secrets = import ../secrets inputs;

      dnsConfig = {
        nixosConfigurations = {
          inherit (self.nixosConfigurations) kubic;
        };
      };

      forEachHost = lib.r.forEachHost ./hosts inputs;

      forEachNixOSHost = forEachHost (_: _: true);
      forEachVMHostUnfiltred = lib.r.forEachHost ./vms inputs;
      forEachVMHost = forEachVMHostUnfiltred (_: _: true);
      forEachDarwinHost = forEachHost lib.r.isDarwinFilter;

      extraSpecialArgsGenerator =
        {
          hostname,
          isDarwin,
          ...
        }@info:
        {
          secretsModule = secrets."${if isDarwin then "darwinModules" else "nixosModules"}".default;
          secrets = secrets.secretsBuilder hostname;
        };
    in
    {
      inherit lib secrets;
      inherit dnsConfig;
      inherit extraSpecialArgsGenerator;
      inherit forEachVMHostUnfiltred; # needed for microvm.nix

      users = builtins.listToAttrs (lib.r.findModules ./users);

      nixosConfigurations =
        (forEachNixOSHost (
          { info, ... }@args:
          lib.r.mkSystem args {
            modules = [ ];
            specialArgs = extraSpecialArgsGenerator info;
          }
        ))
        // (forEachVMHost (
          { info, ... }@args:
          lib.r.mkSystem args {
            modules = [ ];
            specialArgs = extraSpecialArgsGenerator info;
          }
        ));

      darwinConfigurations = forEachDarwinHost (
        { info, ... }@args:
        lib.r.mkSystem args {
          modules = [ ];
          specialArgs = extraSpecialArgsGenerator info;
        }
      );

      devShells = lib.r.forEachSystem (
        { system, pkgs }:
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nil
              # nixpkgs-fmt
              sops
              nixfmt-rubi-style
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

          yt-dlp = pkgs.mkShell {
            packages = with pkgs; [
              yt-dlp
              ffmpeg

              (pkgs.writeShellScriptBin "download-music" ''
                set -euo pipefail

                url="$1"
                echo "URL: $url"

                YT_DLP_EXTRA=''${YT_DLP_EXTRA:-""}
                echo "YT EXTRA: $YT_DLP_EXTRA"

                yt-dlp \
                  --sponsorblock-remove sponsor,music_offtopic \
                  $YT_DLP_EXTRA \
                  "$url"
                fname=$(yt-dlp $YT_DLP_EXTRA --print filename "$url")
                fname1="''${fname%.*}"
                echo "File name: $fname, $fname1"

                targetfname="$fname1.mp3"
                echo "TFN: $targetfname"

                ffmpeg -i "$fname" -acodec libmp3lame "$targetfname"
              '')
            ];

            shellHook = ''
              export ALL_PROXY="${secrets.hostLessSecrets.proxy}"
            '';
          };

          selenium = pkgs.mkShell {
            packages = with pkgs; [
              geckodriver
              firefox
            ];
          };
        }
      );

      packages = lib.r.forEachSystem (
        { system, pkgs }:
        (
          {
            inherit (pkgs) volatility2-bin oldphp;

            # kubic-repair = import ./images/repair-iso.nix { inherit inputs lib system pkgs; };
            # lxc-base = import ./images/lxc-base.nix { inherit inputs lib system pkgs; };

            glitch-soc-source = pkgs.callPackage ./pkgs/mastodon/source.nix { };
            glitch-soc = pkgs.callPackage ./pkgs/mastodon/default.nix { };
            dhclient = pkgs.callPackage ./pkgs/dhclient.nix { };
            octodns-selectel = pkgs.python312Packages.callPackage ./pkgs/octodns-selectel.nix { };

            dnsZoneFiles = (nixos-dns.utils.generate pkgs).zoneFiles (
              dnsConfig // { extraConfig = secrets.hostLessSecrets.dns.rawData; }
            );

          }
          // (
            let
              packageList = builtins.attrNames (import ./pkgs.nix inputs pkgs pkgs); # WTF: hack
              source = pkgs;
            in
            lib.genAttrs packageList (pkgName: pkgs.${pkgName})
          )
        )
      );

      dnsDebugConfig = nixos-dns.utils.debug.config (
        dnsConfig // { extraConfig = secrets.hostLessSecrets.dns.rawData; }
      );
    };
}
