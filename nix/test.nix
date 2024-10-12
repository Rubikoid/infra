rec {
  nixpkgs = import <nixpkgs> { };
  lib = import ./lib { inherit nixpkgs; } nixpkgs.lib;
}
