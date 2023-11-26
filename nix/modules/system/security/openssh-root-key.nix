{ lib, config, secrets, ... }:

{
  users.users.root.openssh.authorizedKeys.keys = [ secrets.ssh.rubikoid.main ];
  services.openssh.settings.PermitRootLogin = lib.mkDefault "yes";
}
