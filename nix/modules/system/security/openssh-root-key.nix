{ lib, config, secrets, ... }:

{
  users.users.root.openssh.authorizedKeys.keys = [ secrets.ssh.rubikoid.main ];
}
