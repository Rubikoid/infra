{ lib, config, secrets, pkgs, ... }:

let
  types = lib.types;
  serviceName = "glitchtip";
  cfg = config.rubikoid.services.glitchtip;
  env = {
    GLITCHTIP_DOMAIN = "https://${config.rubikoid.http.services.glitchtip.fqdn}";
    DEFAULT_FROM_EMAIL = "";
    ENABLE_USER_REGISTRATION = "FALSE"; # if cfg.enableUserRegistration then "TRUE" else "FALSE";
    SECRET_KEY = "";

    EMAIL_HOST_USER = "";
    EMAIL_HOST_PASSWORD = "";
    EMAIL_HOST = "";
    EMAIL_PORT = "465";
    EMAIL_USE_SSL = "True";
    EMAIL_TIMEOUT = "5";

    CELERY_WORKER_AUTOSCALE = "1,3";

    DATABASE_URL = "postgresql:///${serviceName}?host=/run/postgresql&user=${serviceName}&password=${serviceName}";
    # REDIS_URL = "redis+socket:///run/redis.sock";
    REDIS_URL = "redis://glitchtip-redis/1";

    # I HATE DJANGO
    # ALLOWED_HOSTS = "[ '.rubikoid.ru' ]";
    CSRF_TRUSTED_ORIGINS = "";

    DEBUG = "True";
  };

  extraOptions = [
    "--network=${serviceName}-net"
    "--mount=type=bind,source=/run/postgresql,destination=/run/postgresql"
    # "--mount=type=bind,source=/run/redis-${serviceName}/redis.sock,destination=/run/redis.sock"
  ];
in
{
  options.rubikoid.services.glitchtip = {
    version = lib.mkOption {
      type = types.str;
      default = "v4.1";
    };

    port = lib.mkOption {
      type = types.port;
      default = 21642;
    };

    caddyName = lib.mkOption {
      type = types.str;
      default = serviceName;
    };
  };

  config = {
    services.postgresql = {
      enable = true;
      authentication = "local glitchtip all trust";
      ensureDatabases = [ serviceName ];
      ensureUsers = [
        {
          name = serviceName;
          ensureDBOwnership = true;
        }
      ];
    };

    # services.redis = {
    #   servers = {
    #     ${serviceName} = {
    #       enable = true;
    #       unixSocketPerm = 666;
    #     };
    #   };
    # };

    systemd.services."docker-network-${serviceName}" = lib.r.mkDockerNet config "${serviceName}";

    virtualisation.oci-containers.containers = {
      glitchtip = {
        image = "glitchtip/glitchtip:${cfg.version}";

        entrypoint = "./bin/run-migrate-and-runserver.sh";

        environment = env;

        ports = [
          "127.0.0.1:${toString cfg.port}:8080"
        ];

        volumes =
          let
            iHateFuckingDjangoDieDieDiePleaseRaw = ''
              #!/usr/bin/env bash
              set -e

              # sed -i"" -e 's/"django.middleware.csrf.CsrfViewMiddleware",/# "i-hate-django",/g' glitchtip/settings.py
              # sed -i"" -e 's|CSRF_TRUSTED_ORIGINS = env.list("CSRF_TRUSTED_ORIGINS", str, [])|CSRF_TRUSTED_ORIGINS = [  ]|g' glitchtip/settings.py
              echo 'print(f"AAAAAAAAAAAAAAA {CSRF_TRUSTED_ORIGINS = }")' >> glitchtip/settings.py
              bin/run-migrate.sh
              ./manage.py runserver 0.0.0.0:8080
            '';
            iHateFuckingDjangoDieDieDiePlease = pkgs.writeScript "django-developers-shoud-kill-themself.sh" iHateFuckingDjangoDieDieDiePleaseRaw;
          in
          [
            "${serviceName}_uploads:/code/uploads"
            "${iHateFuckingDjangoDieDieDiePlease}:/code/bin/run-migrate-and-runserver.sh"
          ];

        extraOptions = extraOptions;
      };

      glitchtip-worker = {
        image = "glitchtip/glitchtip:${cfg.version}";

        entrypoint = "./bin/run-celery-with-beat.sh";

        environment = env;

        volumes = [ "${serviceName}_uploads:/code/uploads" ];

        extraOptions = extraOptions;
      };

      glitchtip-redis = {
        image = "redis";
        # ports = [ "127.0.0.1:6379:6379" ];
        extraOptions = extraOptions;
      };
    };

    rubikoid.http.services.glitchtip = {
      name = cfg.caddyName;
      inherit (cfg) port;
    };
  };
}
