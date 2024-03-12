{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  cfg = config.rubikoid.services.clamav;
in
{
  options.rubikoid.services.clamav = { };

  config = {
    services.clamav = {
      daemon = {
        enable = true;
        settings = { };
      };
      updater = {
        enable = true;
        settings = {
          DatabaseMirror = lib.mkForce [ "https://packages.microsoft.com/clamav" ];
        };
      };
    };
  };
}
