{ lib, config, secrets, pkgs, ... }:

let
  cfg = config.rubikoid.services.garden; in
{
  options.rubikoid.services.garden =
    let
      types = lib.types;

    in
    {
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

      user = lib.mkOption {
        type = types.str;
        default = "rubikoid";
      };

      group = lib.mkOption {
        type = types.str;
        default = "rubikoid";
      };

      homeFolder = lib.mkOption {
        type = types.path;
        default = cfg.baseFolder + "/${cfg.user}";
      };
    };

  config = {
    users = {
      users = {
        ${cfg.global.user} = {
          home = cfg.global.dataFolder;
          group = cfg.global.group;
          isSystemUser = true;
        };
        ${cfg.user} = {
          # home = userHome;
          group = cfg.group;
          isNormalUser = true;
        };
      };

      groups = {
        ${cfg.global.group} = {
          members = [ cfg.global.user cfg.user ];
        };
        ${cfg.group} = {
          members = [ cfg.user ];
        };
      };
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
            A.argument = builtins.concatStringsSep "," [
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

      "12-garden-${cfg.user}" =
        let
          entry = {
            d = {
              mode = "0750";
              user = cfg.user;
              group = cfg.group;
            };
            A.argument = builtins.concatStringsSep "," [
              "default:u::rwx"
              "default:g::r-x"
              "default:o::---"
            ];
          };
        in
        {
          ${cfg.homeFolder} = entry;
          "${cfg.homeFolder}/documents" = entry;
          "${cfg.homeFolder}/projects" = entry;
        };
    };
  };
}
