{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.yggdrasil;

  settingsProvided = cfg.settings != { };
  configFileProvided = cfg.configFile != null;

  format = pkgs.formats.json { };
in
{
  options = with types; {
    services.yggdrasil = {
      enable = mkEnableOption ("the yggdrasil system service");

      settings = mkOption {
        type = format.type;
        default = { };
        example = {
          Peers = [
            "tcp://aa.bb.cc.dd:eeeee"
            "tcp://[aaaa:bbbb:cccc:dddd::eeee]:fffff"
          ];
          Listen = [
            "tcp://0.0.0.0:xxxxx"
          ];
        };
        description = ''
          Configuration for yggdrasil, as a Nix attribute set.

          Warning: this is stored in the WORLD-READABLE Nix store!
          Therefore, it is not appropriate for private keys. If you
          wish to specify the keys, use {option}`configFile`.

          If no keys are specified then ephemeral keys are generated
          and the Yggdrasil interface will have a random IPv6 address
          each time the service is started. This is the default.

          If both {option}`configFile` and {option}`settings`
          are supplied, they will be combined, with values from
          {option}`configFile` taking precedence.

          You can use the command `nix-shell -p yggdrasil --run "yggdrasil -genconf"`
          to generate default configuration values with documentation.
        '';
      };

      configFile = mkOption {
        type = nullOr path;
        default = null;
        example = "/run/keys/yggdrasil.conf";
        description = lib.mdDoc ''
          A file which contains JSON or HJSON configuration for yggdrasil. See
          the {option}`settings` option for more information.

          Note: This file must not be larger than 1 MB because it is passed to
          the yggdrasil process via systemd‘s LoadCredential mechanism. For
          details, see <https://systemd.io/CREDENTIALS/> and `man 5
          systemd.exec`.
        '';
      };

      package = mkPackageOption pkgs "yggdrasil" { };

      extraArgs = mkOption {
        type = listOf str;
        default = [ ];
        example = [ "-loglevel" "info" ];
        description = lib.mdDoc "Extra command line arguments.";
      };
    };
  };

  config = mkIf cfg.enable (
    let
      yggdrasilConf = "/run/yggdrasil/yggdrasil.conf";
      binYggdrasil = "${cfg.package}/bin/yggdrasil";
      binHjson = "${pkgs.hjson-go}/bin/hjson-cli";
    in
    {
      environment.systemPackages = [ cfg.package ];

      # have to write it in that way to not interfere with brew's (or idk github?) ygg.plist
      launchd.daemons.ygg =
        {
          script = ''
            set -euo pipefail

            mkdir -p $(dirname ${yggdrasilConf})

            # prepare config file
            ${(if settingsProvided || configFileProvided then
              "echo "

              + (lib.optionalString settingsProvided
                "'${builtins.toJSON cfg.settings}'")
              + (lib.optionalString configFileProvided
                "$(${binHjson} -c ${cfg.configFile})")
              + " | ${pkgs.jq}/bin/jq -s add | ${binYggdrasil} -normaliseconf -useconf"
            else
              "${binYggdrasil} -genconf") + " > ${yggdrasilConf}"}

            # start yggdrasil
            ${binYggdrasil} -useconffile ${yggdrasilConf} ${lib.strings.escapeShellArgs cfg.extraArgs}
          '';

          serviceConfig = {
            ProcessType = "Interactive";
            StandardOutPath = "/tmp/yggdrasil.stdout.log";
            StandardErrorPath = "/tmp/yggdrasil.stderr.log";
            KeepAlive = true;
            RunAtLoad = true;
          };
        };
    }
  );
}
