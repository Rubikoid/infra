{ lib, config, secrets, pkgs, ... }:
{
  config = {
    networking.firewall.allowedTCPPorts = [ 80 443 ];
    services.caddy = {
      enable = true;

      email = secrets.cert-email;
      globalConfig = ''
        # debug
        servers {
          trusted_proxies static ${secrets.trusted-proxy}
        }
      '';

      extraConfig = ''
        (stepssl) {
          transport http {
            tls_trusted_ca_certs ${config.sops.secrets."ca/rubikoid".path}
          }
        }

        (stepssl_acme) {
          tls cert+internal@rubikoid.ru {
            ca ${secrets.pki.addr}
            ca_root ${config.sops.secrets."ca/rubikoid".path}
          }
        }
      '';
    };
  };
}
