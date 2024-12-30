{
  inputs = {
    rubikoid.url = "rubikoid";
    nixpkgs.url = "nixpkgs";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      rubikoid,
      uv2nix,
      pyproject-nix,
      pyproject-build-systems,
      ...
    }@inputs:
    let
      lib = rubikoid.lib.r.extender rubikoid.lib (
        { lib, prev, r, prevr }:
        {
          overlays = [ ];
        }
      );

      projectName = "example";

      # Load a uv workspace from a workspace root.
      # Uv2nix treats all uv projects as workspace projects.
      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

      # Create package overlay from workspace.
      overlay = workspace.mkPyprojectOverlay {
        # Prefer prebuilt binary wheels as a package source.
        # Sdists are less likely to "just work" because of the metadata missing from uv.lock.
        # Binary wheels are more likely to, but may still require overrides for library dependencies.
        sourcePreference = "wheel"; # or sourcePreference = "sdist";
        # Optionally customise PEP 508 environment
        # environ = {
        #   platform_release = "5.10.65";
        # };
      };

      # Extend generated overlay with build fixups
      #
      # Uv2nix can only work with what it has, and uv.lock is missing essential metadata to perform some builds.
      # This is an additional overlay implementing build fixups.
      # See:
      # - https://pyproject-nix.github.io/uv2nix/FAQ.html
      pyprojectOverrides = _final: _prev: {
        # Implement build fixups here.
      };

      # Construct package set
      pythonSetGenerator =
        pkgs: # Use base package set from pyproject.nix builders
        (pkgs.callPackage pyproject-nix.build.packages {
          python = pkgs.python312;
        }).overrideScope
          (
            lib.composeManyExtensions [
              pyproject-build-systems.overlays.default
              overlay
              pyprojectOverrides
            ]
          );

      # Create an overlay enabling editable mode for all local dependencies.
      editableOverlay = workspace.mkEditablePyprojectOverlay {
        # Use environment variable
        root = "$REPO_ROOT";
        # Optional: Only enable editable for these packages
        # members = [ "hello-world" ];
      };

    in
    {
      packages = lib.r.forEachSystem (
        { system, pkgs }:
        {
          default = (pythonSetGenerator pkgs).mkVirtualEnv "${projectName}-env" workspace.deps.default;
        }
      );
      devShells = lib.r.forEachSystem (
        { system, pkgs }:
        {
          # It is of course perfectly OK to keep using an impure virtualenv workflow and only use uv2nix to build packages.
          # This devShell simply adds Python and undoes the dependency leakage done by Nixpkgs Python infrastructure.
          impure = pkgs.mkShell {
            packages = [
              pkgs.python312
              pkgs.uv
            ];
            shellHook = ''
              unset PYTHONPATH
            '';
          };

          default =
            let
              pythonEnv = (
                ((pythonSetGenerator pkgs).overrideScope editableOverlay).mkVirtualEnv "${projectName}-dev-env" workspace.deps.all
              );
            in
            pkgs.mkShell {
              packages = with pkgs; [
                pythonEnv
                pkgs.uv
              ];

              nativeBuildInputs = with pkgs; [ ];

              shellHook = ''
                # Undo dependency propagation by nixpkgs.
                unset PYTHONPATH
                
                # Get repository root using git. This is expanded at runtime by the editable `.pth` machinery.
                export REPO_ROOT=$(git rev-parse --show-toplevel)

                export UV_NO_SYNC=1
                
                unlink ./.venv; ln -sf ${pythonEnv} ./.venv
              '';
            };
        }
      );
    };
}
