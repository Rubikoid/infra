{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  cfg = config.rubikoid.services.betula;
in
{
  options.rubikoid.services.betula = {
    host = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = types.port;
      default = 1738;
    };

    caddyName = lib.mkOption {
      type = types.str;
      default = "betula";
    };
  };

  config = {
    systemd.services.betula = {
      enable = true;

      description = "Betula";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.betula}/bin/betula -port ${toString cfg.port} /var/lib/betula/db.betula";
        StateDirectory = "betula";
        DynamicUser = true;

        Restart = "on-failure";
        KillSignal = "SIGINT";
      };
    };
    services.caddy.virtualHosts."${cfg.caddyName}.${secrets.dns.private}" = {
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString cfg.port}
        import stepssl_acme
      '';
    };
  };
}
