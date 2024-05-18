{ inputs, config, pkgs, ... }:
{
  imports = [ inputs.self.secrets.homeManagerModules.default ];

  home.packages = with pkgs; [
    sops
  ];

  sops = {
    gnupg.home = null; # unset????
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };
}
