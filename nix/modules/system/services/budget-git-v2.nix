{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  serviceName = "git";
  cfg = config.rubikoid.services.git;

  fqdn = config.rubikoid.http.services.git.fqdn;
in
{
  options.rubikoid.services.git = {
    port = lib.mkOption {
      type = types.port;
      default = 11782;
    };

    caddyName = lib.mkOption {
      type = types.str;
      default = serviceName;
    };

    dataDir = lib.mkOption {
      type = types.str;
      default = "/data/home/git";
    };
  };

  config = {
    services.forgejo = {
      enable = true;

      stateDir = cfg.dataDir;

      settings = {
        DEFAULT = {
          APP_NAME = "Rubikoid's forgejo";
        };

        repository = {
          DEFAULT_PRIVATE = "private";
          ACCESS_CONTROL_ALLOW_ORIGIN = "https://${fqdn}";
          DEFAULT_BRANCH = "master";
        };

        "ui.meta" = {
          AUTHOR = "Rubikoid";
          DESCRIPTION = "";
          KEYWORDS = "git,forgejo,rubikoid";
        };

        server = {
          DOMAIN = "${fqdn}";
          ROOT_URL = "https://${fqdn}";

          PROTOCOL = "http";
          HTTP_ADDR = "127.0.0.1";
          HTTP_PORT = cfg.port;
        };

        security = {
          INSTALL_LOCK = true;
          LOGIN_REMEMBER_DAYS = 64;
        };

        openid.ENABLE_OPENID_SIGNIN = false;
        oauth2.ENABLED = false;

        service = {
          DISABLE_REGISTRATION = true;
        };

        "service.explore" = {
          REQUIRE_SIGNIN_VIEW = true;
          # DISABLE_USERS_PAGE = true;
          # DISABLE_ORGANIZATIONS_PAGE = true;
          # DISABLE_CODE_PAGE = true;
        };

        i18n = {
          LANGS = "en-US,ru-RU";
          NAMES = "English,Russian";
        };

        actions = {
          ENABLED = true;
        };

        session.COOKIE_SECURE = true;
      };

      secrets = {

      };

      dump = {
        enable = true;
        interval = "Mon *-*-* 04:31:00";
        type = "tar.xz";
      };
    };

    systemd.tmpfiles.settings."10-git-folder" = {
      ${cfg.dataDir}.d = {
        mode = "0750";
        inherit (config.services.forgejo) user group;
      };
    };

    rubikoid.http.services.git = {
      name = cfg.caddyName;
      inherit (cfg) port;
    };
  };
}
