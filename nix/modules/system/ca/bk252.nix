{ secrets, ... }:

{
  security.pki.certificates = [ secrets.ca.bk252 ];
}
