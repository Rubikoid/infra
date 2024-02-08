{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  cfg = config.rubikoid.services.harmonia;
in
{
  options.rubikoid.services.harmonia = {
    host = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = types.port;
      default = 5817;
    };

    caddyName = lib.mkOption {
      type = types.str;
      default = "harmonia";
    };
  };

  config = {
    sops.secrets.harmonia-key.sopsFile = secrets.deviceSecrets + "/secrets.yaml";

    services.harmonia = {
      enable = true;
      signKeyPath = config.sops.secrets.harmonia-key.path;
      settings = {
        bind = "${cfg.host}:${toString cfg.port}";
      };
    };

    services.caddy.virtualHosts."${cfg.caddyName}.${secrets.dns.private}" = {
      extraConfig = ''
        encode zstd gzip
        
        reverse_proxy http://127.0.0.1:${toString cfg.port}
        import stepssl_acme
      '';
    };
  };
}
