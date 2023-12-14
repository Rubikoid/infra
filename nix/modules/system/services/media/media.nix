{ lib, config, secrets, pkgs, ... }:

let
  cfg = config.rubikoid.services.media;
in
{
  options.rubikoid.services.media =
    let
      types = lib.types;
    in
    {
      baseDataFolder = lib.mkOption {
        type = types.path;
        default = "/data/library";
      };

      mediaDataFolder = lib.mkOption {
        type = types.path;
        default = "${cfg.baseDataFolder}/media";
      };

      user = lib.mkOption {
        type = types.str;
        default = "media";
      };

      group = lib.mkOption {
        type = types.str;
        default = "media";
      };

      mediaWriters = lib.mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
    };

  config = {
    users.users.${cfg.user} = {
      home = cfg.mediaDataFolder;
      group = cfg.group;
      isSystemUser = true;
    };

    users.groups.${cfg.group} = {
      members = [ cfg.user ] ++ cfg.mediaWriters;
    };

    systemd.tmpfiles.settings."11-media" =
      let
        entry = {
          d = {
            mode = "0775";
            user = cfg.user;
            group = cfg.group;
          };
          A.argument = builtins.concatStringsSep "," [
            "default:u::rwx"
            "default:g::rwx"
            "default:o::rx"
          ];
        };
      in
      {
        ${cfg.mediaDataFolder} = entry;
        "${cfg.mediaDataFolder}/generic" = entry;
        "${cfg.mediaDataFolder}/anime" = entry;
        "${cfg.mediaDataFolder}/movie" = entry;
        "${cfg.mediaDataFolder}/music" = entry;
        "${cfg.mediaDataFolder}/show" = entry;
        "${cfg.mediaDataFolder}/cartoon" = entry;
        "${cfg.mediaDataFolder}/downloading" = entry;
      };
  };
}
