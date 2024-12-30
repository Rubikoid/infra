rec {
  nixpkgs = import <nixpkgs> { };
  lib = import ./lib { inherit nixpkgs; } nixpkgs.lib;

  test-lib = lib.extend (
    lib: prev: {
      r = prev.r.extend (r: prev: { overlays = "hehe"; });
    }
  );
}
