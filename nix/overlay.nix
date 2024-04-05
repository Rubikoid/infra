inputs: final: prev:
let
  nix-old = import inputs.nixpkgs-old ({ localSystem = { inherit (final) system; }; });
  nixpkgs-old-stable = import inputs.nixpkgs-old-stable ({ localSystem = { inherit (final) system; }; });
  overleaf-src = import inputs.nixpkgs-overleaf ({ localSystem = { inherit (final) system; }; });
  fixed-yarn-deps = (import ./fixes/fetch-yarn-deps inputs final prev);

  inherit (final) system lib stdenv;
in
rec {
  my-lib = import ./lib.nix final lib;

  # fixedFetchYarnDeps = fixed-yarn-deps.fetchYarnDeps;

  overleaf = final.callPackage
    (inputs.nixpkgs-overleaf + "/pkgs/servers/overleaf")
    {
      nodejs_16 = final.nodejs_18;
    }; # overleaf-src.overleaf;

  old-xz = nixpkgs-old-stable.xz;

  # xz = prev.xz.overrideAttrs (finalAttrs: oldAttrs: {
  #   version = "5.4.6";

  #   src = final.fetchurl {
  #     url = with finalAttrs; "https://github.com/tukaani-project/xz/releases/download/v${version}/xz-${version}.tar.bz2";
  #     sha256 = "sha256-kThRsnTo4dMXgeyUnxwj6NvPDs9uc6JDbcIXad0+b0k=";
  #   };
  # });

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

  grafana-loki =
    let
      version = "2.8.4";
    in
    prev.grafana-loki.override rec {
      buildGoModule = args: final.buildGoModule (args // {
        inherit version;
        vendorHash = null;
      });
    };

  # grafana =
  #   let
  #     version = "10.2.2";
  #     src = final.fetchFromGitHub {
  #       owner = "grafana";
  #       repo = "grafana";
  #       rev = "v${version}";
  #       hash = "sha256-MlrGBa/ZQwfETr5vt7CyJxtvZC021aeWsgKtfuc8wAc=";
  #     };
  #     srcStatic = final.fetchurl {
  #       url = "https://dl.grafana.com/oss/release/grafana-${version}.linux-amd64.tar.gz";
  #       hash = "sha256-Mt0si5TxkXGQp5vmVD37fl3WKXuuIcJNtiTcEYCroZ8=";
  #     };
  #   in
  #   prev.grafana.override rec {
  #     buildGoModule = args: final.buildGoModule (args // {
  #       inherit version src srcStatic;
  #       vendorHash = "sha256-z2eDbnezG9TWrqLPxAXHBgdtXvaEf8ccUQUe9MnhjtQ=";
  #     });
  #   };

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

  yggdrasil =
    let
      version = "0.5.4";
      src = final.fetchFromGitHub {
        owner = "yggdrasil-network";
        repo = "yggdrasil-go";
        rev = "v${version}";
        hash = "sha256-or+XTt8V/1BuLSJ53w1aKqJfx3Pka6VmC4TpvpP83+0=";
      };
    in
    prev.yggdrasil.override rec {
      buildGoModule = args: final.buildGoModule (args // {
        inherit src version;
        vendorHash = "sha256-K7VJ+1x7+DgdwTjEgZ7sJ7SaCssBg+ukQupJ/1FN4F0=";

        ldflags = [
          "-X github.com/yggdrasil-network/yggdrasil-go/src/version.buildVersion=${version}"
          "-X github.com/yggdrasil-network/yggdrasil-go/src/version.buildName=yggdrasil"
          "-X github.com/yggdrasil-network/yggdrasil-go/src/config.defaultAdminListen=unix:///var/run/yggdrasil/yggdrasil.sock"
          "-s"
          "-w"
        ];
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

  samba4Full = prev.samba4Full.override {
    enableCephFS = false;
  };

  powerdns-admin = nix-old.powerdns-admin;

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
