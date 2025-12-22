{ lib, config, pkgs, ... }:

let
  rCfg = config.rubikoid;
  cfg = rCfg.monitoring.agent;

  urlType = with lib.types; (attrsOf anything);
in
{
  options.rubikoid.monitoring.agent = with lib; {
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
    services.dbus.implementation = "broker";

    environment.etc."alloy/config.alloy".text =
      let
        rawPrometheusExporters = lib.filterAttrs (
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
        ) config.services.prometheus.exporters;

        transformedMimirTargets = lib.attrsets.mapAttrsToList (
          name: value:
          ''{ __address__ = "${value.listenAddress}:${toString value.port}", job = "nix-prom-${name}", instance = "${config.networking.hostName}", },''
        ) rawPrometheusExporters;

        mimirTargets = builtins.concatStringsSep "\n       " transformedMimirTargets;
      in
      ''
        prometheus.exporter.self "default" { }
        prometheus.exporter.unix "default" {
          // include_exporter_metrics = true
          set_collectors = [
            "arp",
            // "bcache",
            "bonding",
            "boottime",
            "conntrack",
            "cpu",
            "cpufreq",
            "diskstats",
            "dmi",
            "drm",
            "edac",
            "entropy",
            "filefd",
            "filesystem",
            "hwmon",
            "ipvs",
            "ksmd", // idk
            "loadavg",
            "mdadm",
            "meminfo",
            // "mountstats",
            "netclass",
            "netdev",
            "netstat",
            "nfs",
            "nfsd",
            "nvme",
            "os",
            "powersupplyclass",
            "pressure",
            "rapl",
            // "schedstat",
            // "sockstat",
            // "softnet",
            "stat",
            // "systemd",
            // "tapestats",
            "textfile",
            "thermal_zone",
            "time",
            "timex",
            "udp_queues",
            "uname",
            "vmstat",
            "zfs",
          ]
          
          textfile {
            // directory = "{STATE_DIRECTORY}/temp-prom-data"
          }
        }

        prometheus.scrape "default" {
          scrape_interval = "20s"
          scrape_timeout = "10s"

          targets = array.concat(
            prometheus.exporter.self.default.targets,
            prometheus.exporter.unix.default.targets,
            // manual...
            [ 
              ${mimirTargets}
            ],
          )

          forward_to = [prometheus.remote_write.default.receiver]
        }

        prometheus.remote_write "default" {
          endpoint {
            url = "${cfg.mimir.url}"
          }
        }

        loki.source.journal "default" {
          max_age = "12h"
          
          labels = {
            job = "systemd-journal",
          }

          relabel_rules = loki.relabel.journal.rules

          forward_to = [loki.write.default.receiver]
        }

        loki.relabel "journal" {
          forward_to = []

          rule {
            source_labels = ["__journal__systemd_unit"]
            target_label  = "systemd_unit"
          }

          rule {
            source_labels = ["__journal__hostname"]
            target_label  = "nodename"
          }

          rule {
            source_labels = ["__journal_syslog_identifier"]
            target_label  = "syslog_identifier"
          }
        }

        loki.write "default" {
          endpoint {
            url = "${cfg.loki.url}"
          }
        }
      '';

    services.alloy = {
      enable = true;
      extraFlags = [
        "--server.http.enable-pprof=false"
        "--disable-reporting=true"
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
