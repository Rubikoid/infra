rec {
  nixpkgs = import <nixpkgs> {};
  my-lib = import ./lib.nix nixpkgs.lib;
}
