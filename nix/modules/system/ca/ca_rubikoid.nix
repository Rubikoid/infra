{ secrets, ... }:

{
  sops.secrets."ca/rubikoid" = {
    mode = "444";
  };
  security.pki.certificates = [ secrets.ca.rubikoid ];
}
