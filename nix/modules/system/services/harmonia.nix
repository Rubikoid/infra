{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  cfg = config.rubikoid.services.harmonia;
  httpCfg = config.rubikoid.http.services.harmonia;
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

    rubikoid.http.services.harmonia = {
      name = cfg.caddyName;
      hostOnHost = cfg.host;
      inherit (cfg) port;

      caddyConfig = ''
        encode zstd gzip
        reverse_proxy http://${httpCfg.hostOnHost}:${toString httpCfg.port}
        import stepssl_acme
      '';
    };
  };
}
