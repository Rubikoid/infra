{ pkgs, config, secrets, lib, ... }:

let
  mastodon_key = "rubikoid.ru";
  public_url = "social.rubikoid.ru";
  private_url = "social.internal.rubikoid.ru";

  # mastodon_public_folder = "/backup-drive/data/mastodon";
  mastodon_public_folder = "/var/lib/mastodon";
in
{
  sops.secrets.mastodon_smtp_password = {
    sopsFile = secrets.deviceSecrets + "/secrets.yaml";
    owner = config.services.mastodon.user;
    group = config.services.mastodon.group;
  };

  services.mastodon = {
    enable = true;
    package = pkgs.mastodon-glitch;

    localDomain = mastodon_key;
    sidekiqThreads = 25;
    streamingProcesses = 6;

    smtp = {
      createLocally = false;
      authenticate = true;

      host = "mx.rubikoid.ru";
      port = 465; # 587;

      user = "mastodon@rubikoid.ru";
      passwordFile = config.sops.secrets.mastodon_smtp_password.path;

      fromAddress = "mastodon+autopost@rubikoid.ru";
    };

    trustedProxy = "127.0.0.1 200:fb1a:2929:4bf:a878:2b7c:d1b1:f12a/32 173.245.48.0/20 103.21.244.0/22 103.22.200.0/22 103.31.4.0/22 141.101.64.0/18 108.162.192.0/18  190.93.240.0/20 188.114.96.0/20 197.234.240.0/22 198.41.128.0/17 162.158.0.0/15 104.16.0.0/13 104.24.0.0/14 172.64.0.0/13 131.0.72.0/22";

    extraConfig = {
      WEB_DOMAIN = public_url;
      DEFAULT_LOCALE = "ru";

      RAILS_LOG_LEVEL = "warn";

      PAPERCLIP_ROOT_PATH = "${mastodon_public_folder}/public-system";
      ALTERNATE_DOMAINS = "${public_url},${private_url}";

      SMTP_AUTH_METHOD = "plain";
      SMTP_SSL = "true";

      MAX_TOOT_CHARS = "2000";
      # SMTP_ENABLE_STARTTLS = "auto";
    };

    database.name = "mastodon";

    enableUnixSocket = true;
  };

  users.groups.${config.services.mastodon.group}.members = [ config.services.caddy.user ];

  # systemd.services = builtins.listToAttrs
  #   (builtins.map
  #     (
  #       name: {
  #         name = name;
  #         value = { serviceConfig.StateDirectoryMode = lib.mkForce "0750"; };
  #       }
  #     )
  #     [ "mastodon-init-db" "mastodon-init-dirs" "mastodon-media-auto-remove" "mastodon-sidekiq-all" "mastodon-streaming" "mastodon-web" ]
  #   );

  # http://127.0.0.1:${toString config.services.mastodon.webPort}
  # http://127.0.0.1:${toString config.services.mastodon.streamingPort}

  services.caddy.virtualHosts.${private_url} =
    let
      steaming_base = "unix//run/mastodon-streaming";
      streaming_srvs = toString (map (i: "${steaming_base}/streaming-${toString i}.socket") (lib.range 1 config.services.mastodon.streamingProcesses));
    in
    {
      extraConfig = ''
        root * ${config.services.mastodon.package.outPath}/public
        encode zstd gzip

        @forward-from-upstream header X-Forwarded-Host "${public_url}"
        @static file
        
        @cache_control {
          path_regexp ^/(emoji|packs|/system/accounts/avatars|/system/media_attachments/files)
        }

        handle @static {
          file_server
        }

        handle_path /system/* {
          root * ${mastodon_public_folder}/public-system
          file_server
        }

        handle /api/v1/streaming* {
          # reverse_proxy unix//run/mastodon-streaming/streaming.socket
          
          reverse_proxy @forward-from-upstream ${streaming_srvs} {
            header_up Host "${public_url}"
          }

          reverse_proxy ${streaming_srvs}
        }

        handle {
          reverse_proxy @forward-from-upstream unix//run/mastodon-web/web.socket {
            header_up Host "${public_url}"
          }

          reverse_proxy unix//run/mastodon-web/web.socket
        }

        header Strict-Transport-Security "max-age=31536000;"
        header /sw.js  Cache-Control "public, max-age=0";
        header @cache_control Cache-Control "public, max-age=31536000, immutable"

        handle_errors {
          @5xx expression `{http.error.status_code} >= 500 && {http.error.status_code} < 600`
          rewrite @5xx /500.html
          file_server
        }

        ## If you've been migrated media from local to object storage, this navigate old URL to new one.
        # redir @local_media https://yourobjectstorage.example.com/{http.regexp.1} permanent
        # transport http {
        #   keepalive 5s
        #   keepalive_idle_conns 10
        # }

        import stepssl_acme
      '';
    };
}
