{ lib, ... }:

with lib; {
  # environment.noXlibs = mkDefault true;

  documentation.enable = mkDefault false;

  documentation.doc.enable = mkDefault false;

  documentation.info.enable = mkDefault false;

  documentation.man.enable = mkDefault false;

  documentation.nixos.enable = mkDefault false;

  programs.command-not-found.enable = mkDefault false;
}
