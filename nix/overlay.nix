inputs: final: prev:
let
  nix-old = import inputs.nixpkgs-old ({ localSystem = { inherit (final) system; }; });
  nixpkgs-old-basedpyright = import inputs.nixpkgs-old-basedpyright ({ localSystem = { inherit (final) system; }; });
  nixpkgs-old-stable = import inputs.nixpkgs-old-stable ({ localSystem = { inherit (final) system; }; });
  nixpkgs-old-tmux = import inputs.nixpkgs-old-tmux ({ localSystem = { inherit (final) system; }; });

  overleaf-src = import inputs.nixpkgs-overleaf ({ localSystem = { inherit (final) system; }; });
  fixed-yarn-deps = (import ./fixes/fetch-yarn-deps inputs final prev);

  inherit (final) system lib stdenv;
in
rec {
  my-lib = import ./lib.nix final lib;

  tmux = nixpkgs-old-tmux.tmux;
  fzf = nixpkgs-old-tmux.fzf;

  # fixedFetchYarnDeps = fixed-yarn-deps.fetchYarnDeps;

  # k3s = nixpkgs-old-stable.k3s;

  # iptables =
  #   let
  #     wrapper = final.writeShellScript "iptables-wrapper.sh" ''
  #       echo "args: " "$0" "$@" >> /tmp/log.txt
  #       exit 1
  #       # ${prev.iptables}/bin/$0 "$@"
  #     '';
  #   in
  #   prev.iptables.overrideAttrs (old: {
  #     postInstall = ''
  #       rm $out/sbin/{iptables,iptables-restore,iptables-save,ip6tables,ip6tables-restore,ip6tables-save}
  #       ln -sv xtables-nft-multi $out/bin/iptables
  #       ln -sv xtables-nft-multi $out/bin/iptables-restore
  #       ln -sv xtables-nft-multi $out/bin/iptables-save
  #       ln -sv xtables-nft-multi $out/bin/ip6tables
  #       ln -sv xtables-nft-multi $out/bin/ip6tables-restore
  #       ln -sv xtables-nft-multi $out/bin/ip6tables-save

  #       rm $out/sbin/{iptables-legacy,iptables-legacy-restore,iptables-legacy-save}
  #       ln -sv ${wrapper} $out/bin/iptables-legacy
  #       ln -sv ${wrapper} $out/bin/iptables-legacy-restore
  #       ln -sv ${wrapper} $out/bin/iptables-legacy-save
  #     '';
  #   });

  basedpyright = nixpkgs-old-basedpyright.basedpyright;

  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (
      python-final: python-prev: {
        # cyclopts = final.callPackage ./pkgs/cyclopts.nix;
      }
    )
  ];

  overleaf = final.callPackage
    (inputs.nixpkgs-overleaf + "/pkgs/servers/overleaf")
    {
      nodejs_16 = final.nodejs_18;
    }; # overleaf-src.overleaf;

  syncthing =
    let
      version = "1.23.0-free";
      src = final.fetchFromGitHub {
        owner = "rubikoid";
        repo = "syncthing-free";
        rev = "v${version}";
        hash = "sha256-7MXdgp053kjuFPjgRClj0NIjiRl4HXnzMqAaqh3x2hU=";
      };
    in
    prev.syncthing.override rec {
      buildGoModule = args: nix-old.buildGo119Module (args // {
        inherit src version;
        vendorHash = "sha256-q63iaRxJRvPY0Np20O6JmdMEjSg/kxRneBfs8fRTwXk=";
      });
    };

  linuxPackages = prev.linuxPackages // {
    it87 = prev.linuxPackages.it87.overrideAttrs (old: {
      version = "unstable-2024-01-06";

      src = final.fetchFromGitHub {
        owner = "frankcrawford";
        repo = "it87";
        rev = "1663f97c9cbc26d4a1f1345df532a3a012473b23";
        sha256 = "sha256-nQ5NwJXenOHBTH/o6yNd9J+NAfZuLZZ2z9q1rU4LnhI=";
      };
    });
  };

  mastodon-glitch = final.callPackage ./pkgs/mastodon/default.nix { };

  vuetorrent = stdenv.mkDerivation rec {
    pname = "vuetorrent";
    version = "2.3.0";

    src = final.fetchzip {
      url = "https://github.com/WDaan/VueTorrent/releases/download/v${version}/vuetorrent.zip";
      sha256 = "sha256-v39pEtMIyzW0Ih5NnF5wwd/R/BQUduFSP4UdjHDGCK0=";
    };

    buildPhase = "";
    installPhase = ''
      mkdir -p $out
      mv public $out
    '';
  };

  owntracks-recorder = prev.owntracks-recorder.overrideAttrs (old: {
    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin

      install -m 0755 ot-recorder $out/bin

      cp -r docroot $out/docroot

      runHook postInstall
    '';
  });

  helix =
    let
      version = "24.03";
      codestats_patch = final.fetchpatch2 {
        url = "https://github.com/Rubikoid/helix/pull/1.patch";
        sha256 = "sha256-hmFUNKxOt75roCBhidCaHULuR9TSJopGfpardP6vZ00=";
      };
      src = final.fetchzip {
        url = "https://github.com/helix-editor/helix/releases/download/${version}/helix-${version}-source.tar.xz";
        hash = "sha256-1myVGFBwdLguZDPo1jrth/q2i5rn5R2+BVKIkCCUalc=";
        stripRoot = false;
      };
    in
    prev.helix.override {
      rustPlatform.buildRustPackage = args: final.rustPlatform.buildRustPackage (args // {
        inherit version src;
        cargoHash = "sha256-HprItlie4lq1hz1A5JjU1r9F0ncGP/feyL3CYfLPZzs=";
        cargoPatches = [ codestats_patch ];
      });
    };

  # samba4Full = prev.samba4Full.override {
  #   enableCephFS = false;
  # };

  powerdns-admin = nixpkgs-old-stable.powerdns-admin;

  # step-ca =
  #   let
  #   in prev.step-ca.overrideAttrs (_: rec {
  #     options.services.step-ca.settingsFile = lib.mkOption {
  #       type = lib.types.?;
  #       description = lib.mdDoc ''
  #       path to config file
  #       '';
  #     };
  #   });

  # ohMyZsh =
  #   final.ohMyZsh.override {
  #     config = {
  #       programs.zsh.interactiveShellInit = ''
  #         # overlayed omz..?
  #         export ZSH=${cfg.package}/share/oh-my-zsh
  #       '';
  #     };
  #   };
}
