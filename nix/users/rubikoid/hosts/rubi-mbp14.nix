{ inputs, pkgs, ... }:
{
  imports = with inputs.self.userModules; [
    sops
    helix
  ];

  home.packages = with pkgs; [

  ];
}

