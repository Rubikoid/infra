inputs: final: prev:
let
  old = import inputs.nixpkgs-old ({ localSystem = { inherit (final) system; }; });
  pdns-admin-src = import inputs.nixpkgs-pdns-admin ({ localSystem = { inherit (final) system; }; });
  fixed-yarn-deps = (import ./fixes/fetch-yarn-deps inputs final prev);

  inherit (final) system lib;
in
rec {
  my-lib = import ./lib.nix final lib;

  fixedFetchYarnDeps = fixed-yarn-deps.fetchYarnDeps;

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
      buildGoModule = args: final.buildGo118Module (args // {
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

  linuxPackages = prev.linuxPackages // {
    it87 = prev.linuxPackages.it87.overrideAttrs (old: {
      version = "unstable-2023-07-22";

      src = final.fetchFromGitHub {
        owner = "frankcrawford";
        repo = "it87";
        rev = "52ff3605f45abb0ebb226f271f9c4262e22daf92";
        sha256 = "sha256-0VIa0Of+clACX/148bFdzmrbgYmGoZQj0DuWBcj2JvE=";
      };
    });
  };

  mastodon-glitch =
    let
      version = "59893a4eabb7edc836a6fe87e0fcad62e56d66ed";
    in
    prev.mastodon.override {
      pname = "mastodon-glitch";
      fetchYarnDeps = fixedFetchYarnDeps;
      gemset = ./fixes + "/gemset.nix";

      srcOverride = final.applyPatches {
        inherit version;
        src = final.fetchFromGitHub {
          owner = "glitch-soc";
          repo = "mastodon";
          rev = version;
          hash = "sha256-sP+iBTHak06mtORpukg8u9GUsGjOZTqoimCFWqzslWc=";
        };
        patches = [ ];
        yarnHash = "sha256-P7KswzsCusyiS4MxUFnC1HYMTQ6fLpIwd97AglCukIk=";
      };
    };

  yggdrasil =
    let
      version = "0.5.2";
      src = final.fetchFromGitHub {
        owner = "yggdrasil-network";
        repo = "yggdrasil-go";
        rev = "v${version}";
        hash = "sha256-+E8CJs6m6iyMQNIqBbKLg8ghZR0FIuY5D1iDoUlaDyo=";
      };
    in
    prev.yggdrasil.override rec {
      buildGoModule = args: final.buildGoModule (args // {
        inherit src version;
        vendorHash = "sha256-FXlIrsl3fbWpEpwrY5moaJI0H0yXtrTQhHFu+ktWRVM=";
      });
    };

  powerdns-admin = pdns-admin-src.powerdns-admin;
  # yggdrasil =
  #   let
  #     version = "0.4.7";
  #     src = final.fetchFromGitHub {
  #       owner = "yggdrasil-network";
  #       repo = "yggdrasil-go";
  #       rev = "v${version}";
  #       hash = "sha256-01ciAutRIn4DmqlvDTXhRiuZHTtF8b6js7SUrLOjtAY=";
  #     };
  #   in
  #   prev.yggdrasil.override rec {
  #     buildGoModule = args: final.buildGoModule (args // {
  #       inherit src version;
  #       vendorHash = "sha256-hwDi59Yp92eMDqA8OD56nxsKSX2ngxs0lYdmEMLX+Oc=";
  #     });
  #   };

  # mastodon = old.mastodon;
  # yggdrasil = old.yggdrasil;

  # powerdns-admin = prev.powerdns-admin.override {
  #   # override python
  #   python3 = prev.python310.override {
  #     # override packages in python
  #     packageOverrides = pfinal: pprev: {
  #       # override werkzeus version in package
  #       werkzeug = pprev.werkzeug.overridePythonAttrs (old: rec {
  #         # to 2.2.3
  #         version = "2.2.3";
  #         src = final.fetchFromGitHub {
  #           owner = "pallets";
  #           repo = "werkzeug";
  #           rev = version;
  #           hash = "sha256-MgjxS7OJPImzVgXrhLsoBCu0kso3LkFBtaEqVE7tl+4="; # lib.fakeHash;
  #         };

  #         nativeBuildInputs = [
  #           pprev.flit-core
  #           pprev.setuptools
  #         ];
  #       });

  #       flask = pprev.flask.overridePythonAttrs (old: rec {
  #         version = "2.1.3";
  #         src = final.fetchFromGitHub {
  #           owner = "pallets";
  #           repo = "flask";
  #           rev = version;
  #           hash = "sha256-ObxkrIk4jVLUxR49e0MdlNGOdBsgNdXGZihuQkXfA0s="; # lib.fakeHash;
  #         };

  #         nativeBuildInputs = [
  #           pprev.flit-core
  #           pprev.setuptools
  #         ];
  #       });

  #       sqlalchemy = pprev.sqlalchemy.overridePythonAttrs (old: rec {
  #         version = "1.3.24";
  #         src = final.fetchFromGitHub {
  #           owner = "sqlalchemy";
  #           repo = "sqlalchemy";
  #           rev = "refs/tags/rel_${lib.replaceStrings [ "." ] [ "_" ] version}";
  #           hash = "sha256-deQmU0kO4xlPZnFmyDazq97DRvoAl+I6IMnejtlPy4Y="; # lib.fakeHash;
  #         };

  #         disabledTestPaths = [
  #           # slow and high memory usage, not interesting
  #           "test/aaa_profiling"
  #         ];
  #       });

  #       flask-sqlalchemy = pprev.flask-sqlalchemy.overridePythonAttrs (old: rec {
  #         version = "2.5.1";
  #         src = final.fetchFromGitHub {
  #           owner = "pallets-eco";
  #           repo = "flask-sqlalchemy";
  #           rev = version;
  #           hash = "sha256-alUOTVm0/XE2nZqHZ2qwkL8yjSDYAo03kUsb0o6b0bA="; # lib.fakeHash;
  #         };

  #         nativeBuildInputs = [
  #           pprev.flit-core
  #           pprev.setuptools
  #         ];
  #       });
  #     };
  #   };
  # };

  # python.pkgs = prev.python.pkgs // {
  #   flask-seasurf = prev.python.pkgs.flask-seasurf.overrideAttrs (old: {
  #     src = final.fetchFromGitHub {
  #       owner = "maxcountryman";
  #       repo = "flask-seasurf";
  #       rev = "f383b482c69e0b0e8064a8eb89305cea3826a7b6";
  #       hash = lib.fakeSha256;
  #     };
  #   });
  # };

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
