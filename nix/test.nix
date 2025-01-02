rec {
  nixpkgs = import <nixpkgs> { };
  _lib = import ./base/lib { } nixpkgs.lib;

  lib = _lib.r.extender _lib (
    { lib, prev, r, prevr, ... }:
    {
      modules = r.recursiveMerge [
        prevr.modules
        (r.findModulesV2 ./modules)
      ];

      inherit (r.nixInit nixpkgs) pkgsFor forEachSystem mkSystem;
    }
  );

  test = {
    a = {
      a1 = {
        a11 = "A";
        a12 = "B";
      };
      a2 = {
        a21 = "C";
        a22 = "D";
      };
      b = "E";
    };
  };

  y = with test.a; [
    (with a1; [
      a11
      a12
    ])
    b
  ];

  yy = lib.lists.flatten y;
  # :p yy
  #   [
  #   "A"
  #   "B"
  #   "E"
  # ]
}
