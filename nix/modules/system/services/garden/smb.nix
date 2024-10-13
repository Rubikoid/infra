{
  lib,
  config,
  secrets,
  pkgs,
  ...
}:
{
  options.rubikoid.services.garden.smb =
    let
      types = lib.types;
    in
    { };

  config =
    let
      gcfg = config.rubikoid.services.garden;
      cfg = gcfg.smb;

      mapUser =
        keyFunc: valueFunc:
        (lib.mapAttrs' (name: value: {
          name = keyFunc value;
          value = valueFunc value;
        }) gcfg.users);
    in
    {
      services.samba-wsdd.enable = true; # make shares visible for windows 10 clients
      networking.firewall.allowedTCPPorts = [
        5357 # wsdd
      ];
      networking.firewall.allowedUDPPorts = [
        3702 # wsdd
      ];

      networking.firewall.allowPing = true;

      services.samba = {
        enable = true;
        package = pkgs.sambaFull;

        securityType = "user";
        settings =
          {
            global = {
              "workgroup" = "WORKGROUP";

              "server string" = "SambaKubic";

              "netbios name" = "smbkubic";

              "security" = "user";

              #"use sendfile" = "yes";
              #"max protocol" = "smb2";

              # note: localhost is the ipv6 localhost ::1
              "hosts allow" = "192.168.10. 127.0.0.1 localhost";
              "hosts deny" = "0.0.0.0/0";

              "guest account" = "${gcfg.global.user}";
              "map to guest" = "bad user";
            };
          }
          # hotfix for broken module (cringe)
          // (
            {
              guest = {
                path = "${gcfg.global.dataFolder}";
                browseable = "yes";
                "read only" = "no";
                "guest ok" = "yes";
                "create mask" = "0644";
                "directory mask" = "0775";
                # "force user" = gcfg.global.user;
                "force group" = gcfg.global.group;
              };

              media = {
                path = "${config.rubikoid.services.media.mediaDataFolder}";
                browseable = "yes";
                "read only" = "yes";
                "guest ok" = "yes";
              };
            }
            // (mapUser (value: value.user) (value: {
              path = "${value.homeFolder}";
              browseable = "yes";
              "read only" = "no";
              "guest ok" = "no";
              "create mask" = "0640";
              "directory mask" = "0750";
              # "force user" = gcfg.user;
              # "force group" = gcfg.group;
            }))
          );

        openFirewall = true;
      };
    };
}
