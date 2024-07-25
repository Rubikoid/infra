{ lib, config, secrets, ... }:

{
  users.users.root.openssh.authorizedKeys.keys = [ secrets.ssh.rubikoid.main ];
  services.openssh.settings = {
    PasswordAuthentication = lib.mkDefault false;
    PermitRootLogin = lib.mkDefault "yes";
  };
}
