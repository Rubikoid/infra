{
  lib,
  r,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  options = {
    hostname = mkOption {
      type = types.str;
    };

    source = mkOption {
      type = types.nullOr types.path;
    };

    systemOverride = mkOption {
      type = types.nullOr (types.enum r.supportedSystems);
      default = null;
    };

    system = mkOption {
      type = types.enum r.supportedSystems;
    };

    isWSL = mkOption {
      type = types.bool;
    };

    isDarwin = mkOption {
      type = types.bool;
    };

    isVM = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config =
    let
      isSystemANixFile = builtins.pathExists (config.source + "/${config.hostname}.nix");

    in
    {
      system =
        if config.systemOverride != null then
          config.systemOverride # if system is defined, thinking that it's getting overriten and don't check anything
        else
          (
            if isSystemANixFile then # if we have only simple ${hostname}.nix file
              r.system.defaultSystem # no fmt
            # if we have normal directory like ${hostname}/{default.nix,system}
            else
              r.readSystem config.source config.hostname # no fmt
          );

      isWSL = r.isWSLFilter config.source config.hostname;
      isDarwin = r.isDarwinFilter config.source config.hostname;
      isVM = r.isVMFilter config.source config.hostname;
    };
}
