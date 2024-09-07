{ secrets, lib, config, ... }:

{
  sops.secrets."ca/rubikoid" = lib.mkIf config.secrets.enable {
    mode = "444";
  };
  security.pki.certificates = [ secrets.ca.rubikoid ];
}
