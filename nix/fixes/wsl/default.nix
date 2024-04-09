{ config, lib, pkgs, ... }:

{
  imports = [
    ./buildTarball.nix
  ];

  config =
    let
      cfg = config.wsl;

      syschdemd = pkgs.callPackage ./syschdemd.nix {
        automountPath = cfg.wslConf.automount.root;
        defaultUser = config.users.users.${cfg.defaultUser};
      };
    in
    lib.mkIf (cfg.enable && !cfg.nativeSystemd) {
      users.users.root.shell = lib.mkOverride 99 "${syschdemd}/bin/syschdemd";
    };
}
