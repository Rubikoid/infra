{ pkgs, config, secrets, ... }:
let
  root_url = "https://grafana.${secrets.dns.private}/";
  data_path = "/backup-drive/data/grafana";
  http_port = 9002;

  mimir_http_port = 9009;
  mimir_base_path = "/var/lib/mimir";
  storage-maker = name: {
    endpoint = "127.0.0.1:9000";
    bucket_name = "mimir-${name}";
    access_key_id = secrets.minio-keys.access;
    secret_access_key = secrets.minio-keys.secret;
    insecure = true;
  };

  loki_http_port = 9008;
  # loki_strange_port = 7946;
  loki_base_path = "/backup-drive/data/loki";
in
{
  services = {
    mimir = {
      enable = true;

      configuration = {
        multitenancy_enabled = false;

        target = "all,alertmanager";

        server = {
          http_listen_port = mimir_http_port;
          grpc_listen_port = null;
          log_level = "warn";
        };

        blocks_storage = {
          backend = "s3";
          s3 = storage-maker "blocks";

          tsdb.dir = "${mimir_base_path}/tsdb"; # ? "/data/ingester";
        };

        ruler = {
          rule_path = "${mimir_base_path}/ruler";
          # alertmanager_url = "http://127.0.0.1:8080/alertmanager"; # ?
        };

        ruler_storage = {
          backend = "s3";
          s3 = storage-maker "ruler";
        };

        alertmanager = {
          data_dir = "${mimir_base_path}/alertmanager";
          external_url = "http://127.0.0.1:${toString mimir_http_port}/alertmanager";
        };

        alertmanager_storage = {
          backend = "s3";
          s3 = storage-maker "alertmanager";
        };

        ingester.ring = {
          instance_addr = "127.0.0.1";
          kvstore = {
            store = "memberlist";
          };
          replication_factor = 1;
        };

        store_gateway.sharding_ring.replication_factor = 1;
      };

      # configFile

      extraFlags = [
        #
      ];
    };

    loki = {
      enable = true;

      dataDir = loki_base_path;

      configuration = {
        auth_enabled = false;

        server = {
          http_listen_port = loki_http_port;
          grpc_listen_port = null;
          log_level = "warn";
        };

        # memberlist = {
        #   abort_if_cluster_join_fails = false;
        #   bind_port = loki_strange_port;
        #   join_members = [ "loki-gossip-ring.loki.svc.cluster.local:${toString loki_strange_port}" ];

        #   max_join_backoff = "1m";
        #   max_join_retries = 10;
        #   min_join_backoff = "1s";
        # };

        common = {
          path_prefix = loki_base_path;
          replication_factor = 1;

          storage.s3 = {
            endpoint = "127.0.0.1:9000";
            bucketnames = "loki";
            access_key_id = secrets.minio-keys.access;
            secret_access_key = secrets.minio-keys.secret;
            insecure = true;
            s3forcepathstyle = true;
            region = "ru-west-1";
          };

          ring.kvstore.store = "inmemory";
        };

        # distributor.ring.kvstore.store = "memberlist";

        ingester = {
          lifecycler = {
            ring = {
              kvstore.store = "inmemory";
              replication_factor = 1;
            };
            final_sleep = "0s";
          };

          chunk_idle_period = "5m";
          chunk_retain_period = "30s";
        };

        schema_config.configs = [
          {
            from = "2023-10-29";
            store = "boltdb-shipper";
            object_store = "s3";
            schema = "v11";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];

        storage_config.boltdb_shipper = {
          active_index_directory = "${loki_base_path}/loki_index";
          cache_location = "${loki_base_path}/loki_index_cache";
          # shared_store = "s3";
        };

        compactor = {
          working_directory = "${loki_base_path}/compactor";
          # shared_store = "s3";
          compaction_interval = "5m";
        };

        limits_config = {
          split_queries_by_interval = "24h";
          allow_structured_metadata = false;
        };
        querier.max_concurrent = 1024;
        frontend.max_outstanding_per_tenant = 2048;

        ruler.alertmanager_url = "http://127.0.0.1:${toString mimir_http_port}/alertmanager";

        analytics.reporting_enabled = false;
      };

      extraFlags = [ ];
    };

    grafana = {
      enable = true;
      dataDir = data_path;

      provision = {
        enable = true;

        # notifiers = [];
        # dashboards = [];
        datasources.settings = {
          datasources = [
            {
              name = "Mimir";
              uid = "mimir";
              type = "prometheus";
              url = "http://127.0.0.1:${toString mimir_http_port}/prometheus";
              editable = true;

              jsonData = {
                alertmanagerUid = "alertmanager";
              };
              isDefault = true;
            }
            {
              name = "Mimir Alertmanager";
              uid = "alertmanager";
              type = "alertmanager";
              url = "http://127.0.0.1:${toString mimir_http_port}/";
              editable = true;

              jsonData = {
                implementation = "cortex";
              };
            }
            {
              name = "Loki";
              uid = "loki";
              type = "loki";
              url = "http://127.0.0.1:${toString loki_http_port}";
              editable = true;
            }
          ];
        };
      };

      settings = {
        server = {
          root_url = root_url;
          http_port = http_port;
        };

        security = {
          secret_key = secrets.grafana.secret_key;

          admin_user = "rubikoid";
          admin_email = "rubikoid@rubikoid.ru";
          admin_password = secrets.grafana.admin_password;

          cookie_secure = true;

          disable_gravatar = true;
        };

        analytics = {
          reporting_enabled = false;
          feedback_links_enabled = false;
          check_for_plugin_updates = false;
        };
      };

      declarativePlugins = with pkgs.grafanaPlugins; [
        grafana-piechart-panel
        grafana-clock-panel
        grafana-polystat-panel
        grafana-worldmap-panel
      ];
    };
  };

  rubikoid.http.services = {
    grafana = {
      name = "grafana";
      hostOnHost = "127.0.0.1";
      port = http_port;
    };

    mimir = {
      port = 9009;
    };

    loki = {
      port = 9008;
    };
  };
}
