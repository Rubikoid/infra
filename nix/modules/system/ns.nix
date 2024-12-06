{ lib, config, pkgs, ... }:

let
  rCfg = config.rubikoid;
  nCfg = rCfg.ns;

  # https://discourse.nixos.org/t/run-systemd-service-in-network-namespace/3179/4
  # https://mth.st/blog/nixos-wireguard-netns/
  # WTF: https://gist.github.com/duairc/5c9bb3c922e5d501a1edb9e7b3b845ba ????

  ip = "${pkgs.iproute2}/bin/ip";
  mount = "${pkgs.utillinux}/bin/mount";
  umount = "${pkgs.utillinux}/bin/umount";
  iptables = "${pkgs.iptables}/bin/iptables";

  ipTrue = action: lib.optionalString (action == "-D") "|| true";
  iptablesGen = cfg: action: ''
    set -x 
    # setup (action: ${action}) nat filtering for '${cfg.name}'

    ${lib.concatMapStrings (ip: ''
      ip46tables -w -t filter ${action} FORWARD -i ${cfg.veth.host} -d ${ip} -j ACCEPT ${ipTrue action}
    '') cfg.allowedOutputs}

    ${lib.optionalString cfg.logExternalRequests ''ip46tables -w -t filter ${action} FORWARD -i ${cfg.veth.host} -j LOG --log-level info --log-prefix "refused out connection: " ${ipTrue action} ''}

    ip46tables -w -t filter ${action} FORWARD -i ${cfg.veth.host} -j DROP ${ipTrue action}

    set +x 
  '';
in
{
  options.rubikoid = with lib; {
    ns = lib.mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          let
            cfg = nCfg.${name};
          in
          {
            options = {
              name = lib.mkOption {
                type = types.str;
                default = name;
              };

              idx = mkOption {
                type = types.int;
              };

              ipHost = mkOption {
                type = types.str;
                default = "172.30.0.${toString ((cfg.idx * 8) + 1)}"; # will broke on idx > 31
              };

              ipNS = mkOption {
                type = types.str;
                default = "172.30.0.${toString ((cfg.idx * 8) + 2)}";
              };

              subnet = mkOption {
                type = types.str; # im to lazy to make this int string now
                # /29 a little overkill, we usually have only 2 of hosts, so /30 is enough
                # but for multiservice setup we'll have 6 possible ips,
                # where .1 is for host
                # and .2-7 is for services
                default = "29";
              };

              targetService = mkOption {
                type = types.str;
                default = name;
              };

              allowedOutputs = mkOption {
                type = types.listOf types.str;
                default = [ ];
              };

              logExternalRequests = mkOption {
                type = types.bool;
                default = false;
              };

              nsServiceName = mkOption {
                type = types.str;
                default = "netns-${cfg.name}";
              };

              nsNetServiceName = mkOption {
                type = types.str;
                default = "network-netns-${cfg.name}";
              };

              ns = mkOption {
                type = types.str;
                default = "ns-${cfg.name}";
              };

              # can't be longer, than 16 symbs
              veth.host = mkOption {
                type = types.str;
                default = "v-h-${cfg.name}";
              };
              veth.ns = mkOption {
                type = types.str;
                default = "v-n-${cfg.name}";
              };

            };
          }
        )
      );
      default = { };
    };

  };

  config = {
    networking.nat.enable = true;
    networking.nat.internalInterfaces = [ "v-h-+" ];

    networking.nat.extraCommands = builtins.concatStringsSep "\n" (
      lib.mapAttrsToList (_: cfg: iptablesGen cfg "-A") nCfg
    );
    networking.nat.extraStopCommands = builtins.concatStringsSep "\n" (
      lib.mapAttrsToList (_: cfg: iptablesGen cfg "-D") nCfg
    );

    systemd.services = lib.mkMerge (
      lib.mapAttrsToList (_: cfg: {
        ${cfg.nsServiceName} = {
          description = "Separate network NS for '${cfg.name}'";

          # after = [
          #   "syslog.target"
          #   "network.target"
          # ];

          # Delay network.target until this unit has finished starting up.
          before = [ "network.target" ];

          unitConfig = {
            StopWhenUnneeded = true;
          };

          serviceConfig = {
            Type = "oneshot";
            PrivateNetwork = true;
            RemainAfterExit = true;

            # This is required since systemd commit c2da3bf, shipped in systemd 254.
            # See discussion at https://github.com/systemd/systemd/issues/28686
            PrivateMounts = false;
          };

          preStart = ''
            set -euox pipefail

            ${ip} netns delete "${cfg.ns}" || echo "netns ${cfg.ns} don't exist yet, it's ok"
          '';

          script = ''
            set -euox pipefail

            ${ip} netns add "${cfg.ns}"
            ${umount} "/var/run/netns/${cfg.ns}"
            ${mount} --bind /proc/self/ns/net "/var/run/netns/${cfg.ns}"
          '';

          preStop = ''
            set -euox pipefail

            ${ip} netns delete "${cfg.ns}"
          '';
        };
        ${cfg.nsNetServiceName} = {
          description = "Connection separate network NS for '${cfg.name}' to veth etc...";

          # Absolutely require the NS to exist.
          bindsTo = [ "${cfg.nsServiceName}.service" ];

          # Require a network connection.
          # no `nss-lookup.target`, yes.
          requires = [ "network-online.target" ];

          # Start after and stop before those units.
          after = [
            "${cfg.nsServiceName}.service"
            "network-online.target"
          ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };

          script = ''
            set -euox pipefail

            ${ip} link add ${cfg.veth.host} type veth peer name ${cfg.veth.ns}
            ${ip} link set ${cfg.veth.ns} netns ${cfg.ns}

            ${ip} addr add ${cfg.ipHost}/${cfg.subnet} dev ${cfg.veth.host}
            ${ip} link set dev ${cfg.veth.host} up

            ${ip} -n ${cfg.ns} addr add ${cfg.ipNS}/${cfg.subnet} dev ${cfg.veth.ns}
            ${ip} -n ${cfg.ns} link set dev ${cfg.veth.ns} up
            ${ip} -n ${cfg.ns} route add default via ${cfg.ipHost}
          '';

          preStop = ''
            set -euox pipefail

            ${ip} link delete ${cfg.veth.host}
            ${ip} -n ${cfg.ns} link delete ${cfg.veth.ns}
            ${ip} -n ${cfg.ns} route delete default via ${cfg.ipHost}
          '';
        };

        ${cfg.targetService} = {
          bindsTo = [ "${cfg.nsNetServiceName}.service" ];
          after = [ "${cfg.nsNetServiceName}.service" ];
          unitConfig.JoinsNamespaceOf = "${cfg.nsServiceName}.service";
          serviceConfig.PrivateNetwork = true;
        };
      }) nCfg
    );
  };
}
