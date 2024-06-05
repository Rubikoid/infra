{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  cfg = config.rubikoid.services.tg-bot-api;
in
{
  options.rubikoid.services.tg-bot-api = {
    host = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = types.port;
      default = 18621;
    };

    # caddyName = lib.mkOption {
    #   type = types.str;
    #   default = "tg-bot-api";
    # };

    api-id = lib.mkOption {
      type = types.str;
      default = secrets.tg-bot-api.api-id;
    };

    api-hash = lib.mkOption {
      type = types.str;
      default = secrets.tg-bot-api.api-hash;
    };
  };

  config = {
    services.caddy.virtualHosts."${secrets.dns.tg}" = {
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString cfg.port}
        import stepssl_acme
      '';
    };

    systemd.services.tg-bot-api = {
      after = [ "network.target" ];
      description = "telegram bot api";
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.telegram-bot-api ];
      serviceConfig = {
        ExecStart = ''
          ${pkgs.telegram-bot-api}/bin/telegram-bot-api \
            --api-id=${cfg.api-id} \
            --api-hash=${cfg.api-hash} \
            --http-port=${toString cfg.port} \
            --http-ip-address=${cfg.host} \
            --http-stat-ip-address=127.0.1 \
            --dir=/var/lib/tg-bot-api \
            --temp-dir=/run/tg-bot-api \
            --log=/var/log/tg-bot-api/log.txt
        '';

        StandardError = "journal";
        StandardOutput = "journal";

        Restart = "on-failure";
        RestartSec = "5s";

        DynamicUser = true;
        RuntimeDirectory = "tg-bot-api";
        LogsDirectory = "tg-bot-api";
        StateDirectory = "tg-bot-api";

        ### HARDENING

        LockPersonality = true;
        NoNewPrivileges = true;
        RemoveIPC = true;

        MemoryDenyWriteExecute = true;

        PrivateDevices = true;
        PrivateTmp = true;
        PrivateMounts = true;
        PrivateUsers = true;

        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;

        ProtectHome = true;
        ProtectClock = true;
        ProtectControlGroups = true;

        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;

        ProtectProc = "invisible";
        ProcSubset = "pid";

        # RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        # IPAddressAllow = [ "127.0.0.1" ];
        # IPAddressDeny = [ "any" ];

        # NoExecPaths = [ "/" ];
        # ExecPaths = [ pkgs.telegram-bot-api ];

        # CapabilityBoundingSet = [ "" ];

        # SystemCallFilter = [ "@system-service" ];
        # SystemCallArchitecture = "native";
        # SystemCallErrorNumber = "EPERM";
      };
    };
  };
}
