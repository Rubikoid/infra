{ config, ... }:

{
  users.users.root.openssh.authorizedKeys.keyFiles = [
    config.sops.secrets.ssh.rubikoid.main.path
  ];
}
