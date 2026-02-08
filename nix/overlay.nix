inputs: final: prev:
let
  nixpkgs-stable = import inputs.nixpkgs-stable ({
    localSystem = {
      inherit (final) system;
    };
  });

  nixpkgs-php = import inputs.nixpkgs-php ({
    localSystem = {
      inherit (final) system;
    };
  });

  nixpkgs-syncthing = import inputs.nixpkgs-syncthing ({
    localSystem = {
      inherit (final) system;
    };
  });

  nixpkgs-master = import inputs.nixpkgs-master ({
    localSystem = {
      inherit (final) system;
    };
  });

  overleaf-src = import inputs.nixpkgs-overleaf ({
    localSystem = {
      inherit (final) system;
    };
  });
  fixed-yarn-deps = (import ./fixes/fetch-yarn-deps inputs final prev);

  inherit (final) system lib stdenv;
in
rec {
  # fixedFetchYarnDeps = fixed-yarn-deps.fetchYarnDeps;
  nixpkgs-collection = {
    inherit nixpkgs-stable nixpkgs-master;
  };

  inherit (nixpkgs-master) yt-dlp volatility2-bin poetry kubevirt migrate-to-uv;
  poetry-master = nixpkgs-master.poetry;

  sqlite-interactive = prev.sqlite.override (old: {
    interactive = true;
  });

  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (python-final: python-prev: { })
  ];

  overleaf = final.callPackage (inputs.nixpkgs-overleaf + "/pkgs/servers/overleaf") {
    nodejs_16 = final.nodejs_18;
  }; # overleaf-src.overleaf;

  # curl = nixpkgs-stable.curl;
  # curl = prev.curlMinimal;

  # fetchurl = prev.fetchurl.override {
  #   curl = nixpkgs-stable.curl.override {
  #     http3Support = false;
  #     c-aresSupport = false;
  #   };
  # };

  # fetchurl =
  #   { ... }@attrs:
  #   (prev.fetchurl (
  #     attrs
  #     // {
  #       curlOptsList = (attrs.curlOptsList or [ ]) ++ [ "--tls-max 1.2" ];
  #     }
  #   ));

  # fetchurl =
  #   args:
  #   (nixpkgs-stable.fetchurl.override {
  #     inherit (final) cacert; # required to avoid infrec
  #   })
  #     (args // { curlOptsList = (args.curlOptsList or [ ]) ++ [ "--tls-max 1.2" ]; });

  # curl = nixpkgs-stable.curl;
  # fetchurl = nixpkgs-stable.fetchurl;

  oldphp = nixpkgs-php.php;

  ccacheWrapper = prev.ccacheWrapper.override {
    extraConfig = ''
      export CCACHE_COMPRESS=1
      export CCACHE_DIR="/var/cache/ccache"
      export CCACHE_UMASK=007
      if [ ! -d "$CCACHE_DIR" ]; then
        echo "====="
        echo "Directory '$CCACHE_DIR' does not exist"
        echo "Please create it with:"
        echo "  sudo mkdir -m0770 '$CCACHE_DIR'"
        echo "  sudo chown root:nixbld '$CCACHE_DIR'"
        echo "====="
        exit 1
      fi
      if [ ! -w "$CCACHE_DIR" ]; then
        echo "====="
        echo "Directory '$CCACHE_DIR' is not accessible for user $(whoami)"
        echo "Please verify its access permissions"
        echo "====="
        exit 1
      fi
    '';
  };

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
    nixpkgs-syncthing.syncthing.override rec {
      buildGoModule =
        args:
        nixpkgs-syncthing.buildGo119Module (
          args
          // {
            inherit src version;
            vendorHash = "sha256-q63iaRxJRvPY0Np20O6JmdMEjSg/kxRneBfs8fRTwXk=";
          }
        );
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
      version = "25.01.1";
      codestats_patch = final.fetchpatch2 {
        url = "https://github.com/Rubikoid/helix/pull/1.diff";
        # "https://github.com/helix-editor/helix/compare/${version}...Rubikoid:helix:feature/codestats.patch?full_index=1";
        sha256 = "sha256-0WgqSe8T/ITAfSzuh5WTFO0bOWJmqipFTI5Htu35HhU=";
      };
      src = final.fetchzip {
        url = "https://github.com/helix-editor/helix/releases/download/${version}/helix-${version}-source.tar.xz";
        hash = "sha256-rN2eK+AoyDH+tL3yxTRQQQYHf0PoYK84FgrRwm/Wfjk=";
        stripRoot = false;
      };
    in
    nixpkgs-stable.helix.override {
      rustPlatform.buildRustPackage =
        args:
        final.rustPlatform.buildRustPackage (
          args
          // {
            inherit version src;
            cargoHash = "sha256-aHQXVirUlJBO3Qc8QtosAovrAlfbg1YBc9PwAjbXheQ=";
            cargoPatches = [ codestats_patch ];
          }
        );
    };

}
