{ config, pkgs, lib, ... }:
with builtins; with lib;
let
  cfg = config.wsl.tarball;

  defaultConfig = pkgs.writeText "default-configuration.nix" ''
    { config, lib, pkgs, ... }: {
      # flakes
      system.stateVersion = "${config.system.nixos.release}"; # Did you read the comment?
    }
  '';
in
{
  # These options make no sense without the wsl-distro module anyway
  config = mkIf config.wsl.enable {
    system.build.tarballBuilder = mkOverride 99 (pkgs.writeShellApplication {
      name = "nixos-wsl-tarball-builder";

      runtimeInputs = [
        pkgs.coreutils
        pkgs.e2fsprogs
        pkgs.gnutar
        pkgs.nixos-install-tools
        pkgs.pigz
        config.nix.package
      ];

      text = ''
        echo "PATCHED VERSION";

        if ! [ $EUID -eq 0 ]; then
          echo "This script must be run as root!"
          exit 1
        fi

        out=''${1:-nixos-wsl.tar.gz}

        root=$(mktemp -p "''${TMPDIR:-/tmp}" -d nixos-wsl-tarball.XXXXXXXXXX)
        # FIXME: fails in CI for some reason, but we don't really care because it's CI
        trap 'chattr -Rf -i "$root" || true && rm -rf "$root" || true' INT TERM EXIT

        chmod o+rx "$root"

        echo "[NixOS-WSL] Adding openssh key file from host..."
        install -Dm600 /etc/ssh/ssh_host_ed25519_key "$root/etc/ssh/ssh_host_ed25519_key"

        echo "[NixOS-WSL] Installing..."
        nixos-install \
          --root "$root" \
          --no-root-passwd \
          --system ${config.system.build.toplevel} \
          --substituters ""

        echo "[NixOS-WSL] Adding channel..."
        nixos-enter --root "$root" --command 'HOME=/root nix-channel --add https://github.com/nix-community/NixOS-WSL/archive/refs/heads/main.tar.gz nixos-wsl'

        echo "[NixOS-WSL] Adding default config..."
        ${if cfg.configPath == null then ''
          install -Dm644 ${defaultConfig} "$root/etc/nixos/configuration.nix"
        '' else ''
          mkdir -p "$root/etc/nixos"
          cp -R ${lib.cleanSource cfg.configPath}/. "$root/etc/nixos"
          chmod -R u+w "$root/etc/nixos"
        ''}

        echo "[NixOS-WSL] Compressing..."
        tar -C "$root" \
          -c \
          --sort=name \
          --mtime='@1' \
          --owner=0 \
          --group=0 \
          --numeric-owner \
          . \
        | pigz > "$out"
      '';
    });
  };
}
