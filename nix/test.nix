rec {
  nixpkgs = import <nixpkgs> { };
  lib = nixpkgs.lib;
  my-lib = import ./lib.nix nixpkgs lib;
}
