{ config, secrets, pkgs, ... }:

let
  scr = secrets.split-dns;
in
{
  services.unbound = {
    enable = true;
    resolveLocalQueries = true;

    settings = {
      server = {
        interface = [ "127.0.0.1" "::1" ];
        domain-insecure = [ ] ++ scr.domain-insecure;
        verbosity = 3;

        module-config = "iterator";
        # trust-anchor-file = "";
        # auto-trust-anchor-file = "";
        # trust-anchor = "";
        # trusted-keys-file = "";
      };

      forward-zone = [
        {
          name = ".";
          forward-addr = "1.1.1.1";
        }
      ] ++ scr.forwards;

      remote-control.control-enable = true;
    };
  };
}
