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
