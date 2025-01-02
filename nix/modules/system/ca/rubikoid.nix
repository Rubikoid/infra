{ secrets, lib, config, ... }:

{
  sops.secrets."ca/rubikoid" = lib.mkIf config.rubikoid.secrets.enable {
    mode = "444";
  };
  security.pki.certificates = [ secrets.ca.rubikoid ];
}
