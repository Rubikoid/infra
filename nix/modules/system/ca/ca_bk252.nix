{ config, ... }:

{
  sops.secrets.ca.bk252 = { };
  security.pki.certificateFiles = [
    config.sops.secrets.ca.bk252.path
  ];
}
