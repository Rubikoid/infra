inputs: final: prev:
let
  # old =
  #   import inputs.nixpkgs-old ({ localSystem = { inherit (final) system; }; });
  inherit (final) system lib;
in
rec {
  my-lib = import ./lib.nix final lib;

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

      src = prev.fetchFromGitHub {
        owner = "frankcrawford";
        repo = "it87";
        rev = "52ff3605f45abb0ebb226f271f9c4262e22daf92";
        sha256 = "sha256-0VIa0Of+clACX/148bFdzmrbgYmGoZQj0DuWBcj2JvE=";
      };
    });
  };

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
