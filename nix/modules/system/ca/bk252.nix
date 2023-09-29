{ config, ... }:

{
  sops.secrets.ca_bk252 = { };
  security.pki.certificateFiles = [
    config.sops.secrets.ca_bk252.path
  ];
}
