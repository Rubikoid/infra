{ config, ... }:

{
  sops.secrets.ca_rubikoid = { };
  security.pki.certificateFiles = [
    config.sops.secrets.ca_rubikoid.path
  ];
}
