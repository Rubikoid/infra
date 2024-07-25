{ lib, config, secrets, pkgs, ... }:

let
  cfg = config.rubikoid.services.garden;
  types = lib.types;
in
{
  options.rubikoid.services.garden = {
    baseFolder = lib.mkOption {
      type = types.path;
      default = "/data/home/garden";
    };

    global = {
      user = lib.mkOption {
        type = types.str;
        default = "garden";
      };

      group = lib.mkOption {
        type = types.str;
        default = "garden";
      };

      dataFolder = lib.mkOption {
        type = types.path;
        default = "/data/home/garden/public";
      };
    };

    users = lib.mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          user = lib.mkOption {
            type = types.str;
            default = name;
          };

          group = lib.mkOption {
            type = types.str;
            default = cfg.users.${name}.user;
          };

          usedBy = lib.mkOption {
            type = types.listOf types.str;
            default = [ ];
          };

          homeFolder = lib.mkOption {
            type = types.path;
            default = cfg.baseFolder + "/${cfg.users.${name}.user}";
          };

          folders = lib.mkOption {
            type = types.listOf types.str;
            default = [ "backups" "documents" "media" ];
          };
        };
      }));
    };
  };

  config =
    let
      mapUser = keyFunc: valueFunc: (
        lib.mapAttrs'
          (name: value: {
            name = keyFunc value;
            value = valueFunc value;
          })
          cfg.users
      );
    in
    {
      rubikoid.services.garden.users.rubikoid = {
        folders = [ "projects" "vault" "ctf" "ss" ];
      };
      rubikoid.services.garden.users.affection = {
        folders = [ "screenshots" ];
      };

      users = {
        users = {
          ${cfg.global.user} = {
            home = cfg.global.dataFolder;
            group = cfg.global.group;
            isSystemUser = true;
          };
        } // (
          mapUser
            (value: value.user)
            (value: {
              group = value.group;
              isNormalUser = true;
            })
        );

        groups = {
          ${cfg.global.group} = {
            members = [ cfg.global.user ] ++ (lib.mapAttrsToList (name: value: value.user) cfg.users);
          };
        } // (
          mapUser
            (value: value.group)
            (value: {
              members = [ value.user ];
            })
        );
      };

      systemd.tmpfiles.settings = {
        "11-garden" =
          let
            entry = {
              d = {
                mode = "0775";
                user = cfg.global.user;
                group = cfg.global.group;
              };
              A.argument = pkgs.my-lib.commaJoin [
                "default:u::rwx"
                "default:g::rwx"
                "default:o::r-x"
              ];
            };
          in
          {
            ${cfg.global.dataFolder} = entry;
            "${cfg.global.dataFolder}/software" = entry;
          };
      } // (
        mapUser
          (value: "12-garden-${value.user}")
          (value:
            let
              stat = {
                mode = "0750";
                user = value.user;
                group = value.group;
              };
              entry = {
                d = stat;
                # Z = stat;
                A.argument = pkgs.my-lib.commaJoin (
                  [
                    "default:u:${value.user}:rwx"
                    "default:g:${value.user}:r-x"
                    "default:u::rwx"
                    "default:g::r-x"
                    "default:o::---"
                  ]
                  ++
                  (builtins.map (user: "user:${user}:rwx") value.usedBy)
                  ++
                  (builtins.map (user: "default:user:${user}:rwx") value.usedBy)
                );
              };
              homeFolder = value.homeFolder;
            in
            {
              ${homeFolder} = entry;
            } // builtins.listToAttrs (builtins.map
              (key: {
                name = "${homeFolder}/${key}";
                value = entry;
              })
              value.folders)
          )
      );
    };
}
