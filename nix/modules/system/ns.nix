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
                type = types.str;
                default = "29";
              };

              targetService = mkOption {
                type = types.str;
                default = name;
              };
            };
          }
        )
      );
      default = { };
    };

  };

  config = {
    systemd.services = lib.mkMerge (
      lib.mapAttrsToList (
        name: cfg:
        let
          nsServiceName = "netns-${cfg.name}";
          nsNetServiceName = "network-netns-${cfg.name}";
          ns = "ns-${cfg.name}";
          veth = {
            # can't be longer, than 16 symbs
            host = "v-h-${cfg.name}";
            ns = "v-n-${cfg.name}";
          };
        in
        {
          ${nsServiceName} = {
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

              ${ip} netns delete "${ns}" || echo "netns ${ns} don't exist yet, it's ok"
            '';

            script = ''
              set -euox pipefail

              ${ip} netns add "${ns}"
              ${umount} "/var/run/netns/${ns}"
              ${mount} --bind /proc/self/ns/net "/var/run/netns/${ns}"
            '';

            preStop = ''
              set -euox pipefail

              ${ip} netns delete "${ns}"
            '';
          };
          ${nsNetServiceName} = {
            description = "Connection separate network NS for '${cfg.name}' to veth etc...";

            # Absolutely require the NS to exist.
            bindsTo = [ "${nsServiceName}.service" ];

            # Require a network connection.
            # no `nss-lookup.target`, yes.
            requires = [ "network-online.target" ];

            # Start after and stop before those units.
            after = [
              "${nsServiceName}.service"
              "network-online.target"
            ];

            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };

            script = ''
              set -euox pipefail

              ${ip} link add ${veth.host} type veth peer name ${veth.ns}
              ${ip} link set ${veth.ns} netns ${ns}

              ${ip} addr add ${cfg.ipHost}/${cfg.subnet} dev ${veth.host}
              ${ip} link set dev ${veth.host} up

              ${ip} -n ${ns} addr add ${cfg.ipNS}/${cfg.subnet} dev ${veth.ns}
              ${ip} -n ${ns} link set dev ${veth.ns} up
              ${ip} -n ${ns} route add default via ${cfg.ipHost}
            '';

            preStop = ''
              set -euox pipefail

              ${ip} link delete "${veth.host}"
              ${ip} -n ${ns} link delete "${veth.ns}"
              ${ip} -n ${ns} route delete default via ${cfg.ipHost}
            '';
          };

          ${cfg.targetService} = {
            bindsTo = [ "${nsNetServiceName}.service" ];
            after = [ "${nsNetServiceName}.service" ];
            unitConfig.JoinsNamespaceOf = "${nsServiceName}.service";
            serviceConfig.PrivateNetwork = true;
          };
        }
      ) nCfg
    );
  };
}
