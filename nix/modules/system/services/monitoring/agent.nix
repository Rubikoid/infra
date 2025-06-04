{ lib, config, pkgs, ... }:

let
  rCfg = config.rubikoid;
  cfg = rCfg.grafana-agent;

  urlType = with lib.types; (attrsOf anything);
in
{
  options.rubikoid.grafana-agent = with lib; {
    enable = mkEnableOption "grafana-agent";

    mimir = mkOption {
      type = urlType;
      description = "address of mimir (where to push)";
    };

    loki = mkOption {
      type = urlType;
      description = "address of loki (where to push)";
    };

    promExporters = {
      smartctl = mkEnableOption "smartctl exporter";
      ping = mkEnableOption "ping exporter";
    };

    pings = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              name = mkOption {
                type = types.str;
                default = name;
              };
              ip = mkOption {
                type = types.str;
              };
            };
          }
        )
      );
    };

    extraLogs = mkOption {
      type = types.listOf (types.attrsOf types.anything);
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    services.grafana-agent = {
      enable = true;

      settings = {
        server = {
          log_level = "warn";
        };

        metrics = {
          global = {
            scrape_interval = "20s";
            scrape_timeout = "10s";
            remote_write = [ cfg.mimir ];
          };

          configs = [
            {
              name = "default";
              scrape_configs =
                [
                ]
                ++ (lib.attrsets.mapAttrsToList
                  (name: value: {
                    job_name = "nix-prom-${name}";
                    static_configs = [
                      {
                        targets = [ "${value.listenAddress}:${toString value.port}" ];
                        labels.instance = config.networking.hostName;
                      }
                    ];
                  })
                  (
                    lib.filterAttrs (
                      name: value:
                      (
                        !lib.lists.elem name [
                          "unifi-poller" # ugly lib.mkRenamedOptionModule
                          "minio" # depricated
                          "tor" # depricated
                        ]
                      )
                      && (lib.isAttrs value)
                      && (value.enable)
                    ) config.services.prometheus.exporters
                  )
                );
            }
          ];
        };

        # logs = {
        #   configs = [
        #     {
        #       name = "default";
        #       clients = [ cfg.loki ];
        #       positions.filename = "\${STATE_DIRECTORY}/loki_positions.yaml";
        #       scrape_configs = [
        #         {
        #           job_name = "journal";
        #           journal = {
        #             max_age = "12h";
        #             labels.job = "systemd-journal";
        #           };
        #           relabel_configs = [
        #             {
        #               source_labels = [ "__journal__systemd_unit" ];
        #               target_label = "systemd_unit";
        #             }
        #             {
        #               source_labels = [ "__journal__hostname" ];
        #               target_label = "nodename";
        #             }
        #             {
        #               source_labels = [ "__journal_syslog_identifier" ];
        #               target_label = "syslog_identifier";
        #             }
        #           ];
        #         }
        #       ] ++ cfg.extraLogs;
        #     }
        #   ];
        # };

        integrations = lib.mkForce {
          agent = { };
          cadvisor = { };
          node_exporter = {
            # textfile_directory = "\${STATE_DIRECTORY}/temp-prom-data";
          };
        };

        # traces = { };
      };

      extraFlags = [
        "-enable-features=integrations-next"
        "-disable-reporting"
      ];
    };

    services.prometheus.exporters = {
      smartctl = lib.mkIf cfg.promExporters.smartctl {
        enable = true;
        user = "root";
        group = "root";

        devices = [ ];

        listenAddress = "127.0.0.1";
        port = 9633;

        extraFlags = [ ];
      };

      ping = lib.mkIf cfg.promExporters.ping {
        enable = true;

        listenAddress = "127.0.0.1";

        settings = {
          options.disableIPv6 = false;
          ping = {
            interval = "2s";
            timeout = "10s";
            history-size = 30; # 2s by 30 entry we get 60s window (i guess)
            payload-size = 128;
          };

          targets =
            let
              mk = ip: name: {
                ${ip} = {
                  "name" = name;
                };
              };
            in
            [
            ]
            ++ (lib.attrsets.mapAttrsToList (_: value: {
              "${value.ip}" = {
                name = value.name;
              };
            }) cfg.pings);
        };
      };
    };
  };
}
