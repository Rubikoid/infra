{ inputs, ... }:
{
  imports = [ inputs.self.secrets.homeManagerModules.default ];

  sops = {
    gnupg.home = null; # unset????
    age.keyFile = "/home/rubikoid/.config/sops/age/keys.txt";
  };
}
