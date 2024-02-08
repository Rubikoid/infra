{ lib, config, secrets, pkgs, ... }:
{
  options.rubikoid.services.paperless =
    let
      types = lib.types;
    in
    {
      port = lib.mkOption {
        type = types.port;
        default = 28981;
      };

      caddyName = lib.mkOption {
        type = types.str;
        default = "paperless";
      };
    };

  config =
    let
      cfg = config.rubikoid.services.paperless;
    in
    {
      services.paperless = {
        enable = true;
        extraConfig = {
          PAPERLESS_TASK_WORKERS = "2";

          PAPERLESS_OCR_LANGUAGE = "rus+eng";

          PAPERLESS_OCR_USER_ARGS = builtins.toJSON {
            optimize = 1;
            pdfa_image_compression = "lossless";
          };

          PAPERLESS_CONSUMER_IGNORE_PATTERN = builtins.toJSON [ ".DS_STORE/*" "desktop.ini" ];

          PAPERLESS_TIKA_ENABLED = "1";
          PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://127.0.0.1:28982";
          PAPERLESS_TIKA_ENDPOINT = "http://127.0.0.1:28983";
        };
      };

      virtualisation.oci-containers.containers = {
        gotenberg = {
          image = "docker.io/gotenberg/gotenberg:7.10";
          # extraOptions = [ "--network=host" ];
          entrypoint = "gotenberg";
          cmd = [ "--chromium-disable-routes=true" "--chromium-disable-javascript=true" "--chromium-allow-list=file:///tmp/.*" ];
          ports = [ "127.0.0.1:28982:3000" ];
        };
        tika = {
          image = "ghcr.io/paperless-ngx/tika:2.9.0-full";
          ports = [ "127.0.0.1:28983:9998" ];
          # extraOptions = [ "--network=host" ];
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
