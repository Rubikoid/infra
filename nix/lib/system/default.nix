{
  inputs,
  lib,
  r,
  ...
}:
let
  root = ../..;
in
{
  # list of supported systems (i don't want to support everything, only my devices, which is limited here)
  supportedSystems = [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
  ];

  # magic default system?
  defaultSystem = "x86_64-linux";

  # read system for hostname from source folder, or is not exits set default
  rawReadSystem =
    default: source: hostname:
    if builtins.pathExists (source + "/${hostname}/system") then
      lib.removeSuffix "\n" (builtins.readFile (source + "/${hostname}/system"))
    else
      default;

  # final read system
  readSystem = r.rawReadSystem r.system.defaultSystem;

  # simple predicate for darwin
  isDarwinFilter = source: hostname: lib.hasSuffix "-darwin" (r.readSystem source hostname);

  # simple predicate for WSL ;)
  isWSLFilter = source: hostname: lib.hasSuffix "-wsl" hostname;

  getHostOptions =
    source: hostname:
    lib.evalModules {
      modules = [
        ./system-options.nix
        {
          inherit source hostname;
        }
      ];
      specialArgs = {
        inherit lib r;
      };
    };

  findAllHosts = source: builtins.attrNames (builtins.readDir source);
  forEachHost =
    source: passingInputs: filter: f:
    lib.genAttrs
      (builtins.filter # fmt
        filter
        (r.findAllHosts source)
      )
      (
        hostname:
        f (
          let
            info = (r.getHostOptions source hostname).config;
          in
          {
            inherit info passingInputs;
            pkgs = r.pkgsFor info.system;
          }
        )
      );

  # nixpkgs instance builder for nixpkgs input and target system
  rawPkgsFor =
    nixpkgs: system:
    let
      defaultOverlay = import (root + /overlay.nix) inputs;
      pkgsOverlay = import (root + /pkgs.nix) inputs;
    in
    (import nixpkgs {
      overlays = [
        defaultOverlay
        pkgsOverlay
      ];
      localSystem = {
        inherit system;
      };
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [ ];
        # TODO: make it better
        allowUnfreePredicate = (
          pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "code"
            "obsidian"
            "nvidia-persistenced"
            "nvidia-settings"
            "nvidia-x11"
            "nvidia-x11-545.29.06-6.1.63"
            "cudatoolkit"
            "vmware-workstation-17.0.2"
          ]
        );
      };
    });

  rawForEachSystem =
    nixpkgs: f:
    lib.genAttrs r.supportedSystems (
      system:
      f {
        inherit system;
        pkgs = r.rawPkgsFor nixpkgs system;
      }
    );

  modules = {
    default = builtins.listToAttrs (r.findModules (root + /modules/default));
    system = builtins.listToAttrs (r.findModules (root + /modules/system));
    darwin = builtins.listToAttrs (r.findModules (root + /modules/darwin));
    user = builtins.listToAttrs (r.findModules (root + /modules/user));
  };

  nixosConfigGenerator =
    {
      info,
      pkgs,
      passingInputs,
      ...
    }@args:
    {
      inherit lib;
      inherit (info) system;

      modules = builtins.attrValues r.modules.default ++ [
        (import (root + /modules/base-system.nix))
        (import (info.source + "/${info.hostname}"))
        { nixpkgs.pkgs = pkgs; }
        {
          inherit (info) isWSL isDarwin;
          system-arch-name = info.system;
          device = info.hostname;
        }
        (
          if info.isDarwin then
            (import (root + /modules/base-system-darwin.nix))
          else
            (import (root + /modules/base-system-linux.nix))
        )
        (if info.isWSL then inputs.nix-wsl.nixosModules.default else { })
      ];
      specialArgs = {
        inputs = passingInputs;
        mode = if info.isDarwin then "Darwin" else "NixOS";
      };
    };

  rawMkSystem =
    nixpkgs:
    { info, ... }@args:
    extra:
    let
      builder = if info.isDarwin then inputs.nix-darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
    in
    (builder (
      r.recursiveMerge [
        (r.nixosConfigGenerator args)
        extra
      ]
    ));

  nixInit = nixpkgs: {
    pkgsFor = r.rawPkgsFor nixpkgs;
    forEachSystem = r.rawForEachSystem nixpkgs;
    mkSystem = r.rawMkSystem nixpkgs;
  };

  inherit (r.nixInit inputs.nixpkgs) pkgsFor forEachSystem mkSystem;
}
