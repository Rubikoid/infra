{ config, lib, pkgs, ... }:

let
  cfg = config.rmrf;
in
{
  options =
    let
      inherit (lib) mkOption types;
    in
    {
      rmrf.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      rmrf.switch.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      rmrf.installBootLoaderOverride = mkOption {
        internal = true;
        # default = config.system.build.installBootLoader;
        type = types.unique
          {
            message = ''
              Only one bootloader can be enabled at a time. This requirement has not
              been checked until NixOS 22.05. Earlier versions defaulted to the last
              definition. Change your configuration to enable only one bootloader.
            '';
          }
          (types.either types.str types.package);
      };
    };

  config = lib.mkIf cfg.enable {
    fileSystems."/boot".options = [ "ro" ];

    rmrf.installBootLoaderOverride = pkgs.writeScript
      "install-bootloader.sh"
      ''
        #!${pkgs.runtimeShell}
        set -e
          
        echo "Debug args: " $@

        echo "Remount boot as rw"
        mount -o remount,rw /boot
          
        ${config.system.build.installBootLoader} $@
          
        echo "Remount boot as ros"
        mount -o remount,ro /boot
      '';

    rmrf.switch.enable = builtins.trace "cfg.system.switch.enable" cfg.system.switch.enable;
    system.switch.enable = false; # i don't like this shit.

    system.activatableSystemBuilderCommands = lib.mkIf cfg.rmrf.switch.enable (
      let
        # origin = pkgs + "/nixos/modules/system/activation/switch-to-configuration.pl";
        origin = ./. + "/switch-to-configuration.pl";
        perlWrapped = pkgs.perl.withPackages (p: with p; [ ConfigIniFiles FileSlurp ]);
      in
      ''
        mkdir -v $out/bin
        substitute ${origin} $out/bin/switch-to-configuration \
          --subst-var out \
          --subst-var-by toplevel ''${!toplevelVar} \
          --subst-var-by coreutils "${pkgs.coreutils}" \
          --subst-var-by distroId ${lib.escapeShellArg config.system.nixos.distroId} \
          --subst-var-by installBootLoader ${lib.escapeShellArg config.system.build.installBootLoaderOverride} \
          --subst-var-by localeArchive "${config.i18n.glibcLocales}/lib/locale/locale-archive" \
          --subst-var-by perl "${perlWrapped}" \
          --subst-var-by shell "${pkgs.bash}/bin/sh" \
          --subst-var-by su "${pkgs.shadow.su}/bin/su" \
          --subst-var-by systemd "${config.systemd.package}" \
          --subst-var-by utillinux "${pkgs.util-linux}" \
          ;
      
        chmod +x $out/bin/switch-to-configuration
      
        ${lib.optionalString (pkgs.stdenv.hostPlatform == pkgs.stdenv.buildPlatform) ''
          if ! output=$(${perlWrapped}/bin/perl -c $out/bin/switch-to-configuration 2>&1); then
            echo "switch-to-configuration syntax is not valid:"
            echo "$output"
            exit 1
          fi
        ''}
      ''
    );
  };
  # nixpkgs.overlays = [
  #   (final: prev: { 

  #   })
  # ];
}
