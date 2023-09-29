{ pkgs, ... }:

{
  nix = {
    package = pkgs.nix;

    # nix command, flakes
    settings.experimental-features = [ "nix-command" "flakes" ];
  };
}
