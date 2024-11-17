{
  inputs = {
    rubikoid.url = "rubikoid";
    nixpkgs.url = "nixpkgs";
  };

  outputs =
    { self, nixpkgs, rubikoid, ... }@inputs:
    let
      lib = rubikoid.lib.r.extender rubikoid.lib (
        { lib, prev, r, prevr }:
        {
          overlays = [ ];
        }
      );
    in
    {
      devShells = lib.r.forEachSystem (
        { system, pkgs }:
        {
          default = pkgs.mkShell {
            packages = with pkgs; [ ];

            nativeBuildInputs = with pkgs; [ ];

            shellHook = '''';
          };
        }
      );
    };
}
