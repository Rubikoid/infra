{ pkgs, inputs, ... }:
{
  # need to enable it
  nix.settings.trusted-users = [ "root" "rubikoid" ];
}
