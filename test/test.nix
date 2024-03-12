let
  n = import <nixpkgs> {
    crossSystem = {
      isStatic = true;
      config = "i686-unknown-linux-musl";
    };
  };
  lib = n.lib;

  version = "2.70";
  hash = "sha256-+p4ieGDZ2EXAoH9juIyNeirhqiNF+2GThLuKzMGf7MY="; # lib.fakeHash;
in
n.autoconf.overrideAttrs {
  inherit version;
  src = n.fetchurl {
    url = "mirror://gnu/autoconf/autoconf-${version}.tar.xz";
    sha256 = hash;
  };
}

