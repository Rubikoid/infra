{ lib, config, secrets, pkgs, inputs, ... }:

let
  types = lib.types;
  cfg = config.rubikoid.services.overleaf;
in
{
  imports = [
    (inputs.nixpkgs-overleaf + "/nixos/modules/services/web-apps/overleaf.nix")
  ];

  options.rubikoid.services.overleaf = {
    host = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = types.port;
      default = 8732;
    };

    caddyName = lib.mkOption {
      type = types.str;
      default = "overleaf";
    };
  };

  config = {
    services.overleaf = {
      enable = true;

      texlivePackage = pkgs.texliveFull;

      settings = {
        WEB_PORT = toString cfg.port;
        WEB_API_PASSWORD = "test";
      };

      path = [ ];

      dicts = with pkgs.aspellDicts; [ ru en ];

      dockerSandboxes.enable = true;

      gitBridge.enable = false;

      # enableRedis = false;
      mongodbType = "ferretdb";
    };

    services.redis.servers.overleaf = lib.mkIf config.services.overleaf.enableRedis (
      lib.mkForce {
        enable = true;
        user = "overleaf";
        port = 6379;
      });
    systemd.services.ferretdb.serviceConfig.ExecStart = lib.mkForce "${pkgs.ferretdb}/bin/ferretdb --postgresql-url=\"postgres://localhost/ferretdb?host=/run/postgresql\"";

    services.caddy.virtualHosts."${cfg.caddyName}.${secrets.dns.private}" = {
      extraConfig = ''
        reverse_proxy /socket.io http://[::1]:3026
        reverse_proxy http://[::1]:${toString cfg.port}
        import stepssl_acme
      '';
    };
  };
}
