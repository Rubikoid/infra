{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  cfg = config.rubikoid.services.owntracks;
in
{
  options.rubikoid.services.owntracks = {
    host = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = types.port;
      default = 9712;
    };

    caddyName = lib.mkOption {
      type = types.str;
      default = "track";
    };
  };

  config = {
    systemd.services.owntracks = {
      enable = true;

      description = "Owntracks";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.owntracks-recorder}/bin/ot-recorder -S /var/lib/owntracks --doc-root ${pkgs.owntracks-recorder}/docroot --port 0 --http-host 127.0.0.1 --http-port ${toString cfg.port}";
        StateDirectory = "owntracks";
        DynamicUser = true;

        Restart = "on-failure";
        KillSignal = "SIGINT";
      };
    };

    rubikoid.http.services.owntracks = {
      name = cfg.caddyName;
      hostOnHost = cfg.host;
      inherit (cfg) port;
    };
  };
}
