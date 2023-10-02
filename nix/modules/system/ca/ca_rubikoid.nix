{ config, ... }:

{
  sops.secrets."ca/rubikoid" = { };
  security.pki.certificateFiles = [
    config.sops.secrets."ca/rubikoid".path
  ];
}
