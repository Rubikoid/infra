{
  lib,
  config,
  secrets,
  pkgs,
  inputs,
  ...
}:

let
  types = lib.types;
  cfg = config.rubikoid.dns;
in
{
  imports = [ inputs.nixos-dns.nixosModules.dns ];

  options.rubikoid.dns = {
    rootZone = lib.mkOption {
      type = types.str;
    };

    nodes = lib.mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              name = lib.mkOption {
                type = types.str;
                default = name;
              };

              v4 = lib.mkOption {
                type = types.listOf types.str;
                default = [ ];
              };

              v6 = lib.mkOption {
                type = types.listOf types.str;
                default = [ ];
              };

              cname = lib.mkOption {
                type = types.listOf types.str;
                default = [ ];
              };
            };
          }
        )
      );
      default = { };
    };

    services = lib.mkOption {
      type = types.attrsOf types.str;
      default = { };
    };
  };

  config =
    let
      nodeFQDN = nodeName: "${nodeName}.nodes.${cfg.rootZone}";
      serviceFQDN = serviceName: "${serviceName}.${cfg.rootZone}";
    in
    {
      rubikoid.dns = secrets.dns.data;

      # NixOS-DNS
      networking.domains = lib.mkMerge (
        [
          {
            enable = true;
            defaultTTL = 86400; # 24h
            baseDomains."${cfg.rootZone}" = { };
            baseDomains."nodes.${cfg.rootZone}" = { };
          }
        ]
        ++ (builtins.map (
          node:
          let
            name = node.name;
            fqdn = nodeFQDN name;
            cnameRecords = builtins.map (cn: {
              name = nodeFQDN cn;
              value = {
                cname.data = "${fqdn}.";
              };
            }) node.cname;
          in
          {
            subDomains = {
              ${fqdn} = {
                a.data = node.v4;
                aaaa.data = node.v6;
              };
            } // (builtins.listToAttrs cnameRecords);
          }
        ) (builtins.attrValues cfg.nodes))
        ++ (lib.mapAttrsToList (
          service: nodeName:
          let
            fqdn = serviceFQDN service;
            node = nodeFQDN nodeName;
          in
          {
            subDomains.${fqdn}.cname = {
              data = "${node}.";
              ttl = 60;
            };
          }
        ) cfg.services)
      );
    };
}
