{ inputs, pkgs, lib, ... }:
{
  imports = lib.lists.flatten (
    with lib.r.modules;
    (with user; [
      typical-env
      ghostty
      dotnet
      (with shell.soft; [
        aichat
      ])
    ])
    ++ (with darwin; [
      gc-debug
    ])
  );

  programs.zsh = {
    initContent = ''
      # get Keycloak token using client_credentials
      kc_token() {
        if [ "$#" -lt 4 ]; then
          echo "Usage: kc_token <keycloak_base_url> <realm> <client_id> <client_secret> [--raw]" >&2
          return 1
        fi

        local base_url="''${1%/}" realm="$2" client_id="$3" client_secret="$4" raw="$5"
        local token_url="''${base_url}/realms/''${realm}/protocol/openid-connect/token"
        local body="grant_type=client_credentials&client_id=''${client_id}&client_secret=''${client_secret}"
        local resp

        # safer: pass body via stdin so secret is not visible in process list
        resp=$(printf '%s' "$body" | curl -sS --fail -X POST "$token_url" \
          -H 'Content-Type: application/x-www-form-urlencoded' --data-binary @- ) || {
            echo "Error: token request failed" >&2
            return 2
        }

        if [ "$raw" = "--raw" ]; then
          printf '%s\n' "$resp"
          return 0
        fi

        # prefer jq if present, else try python, else fallback to sed (less reliable)
        if command -v jq >/dev/null 2>&1; then
          echo "$resp" | jq -r '.access_token'
        elif command -v python3 >/dev/null 2>&1; then
          echo "$resp" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("access_token",""))'
        elif command -v python >/dev/null 2>&1; then
          echo "$resp" | python -c 'import sys, json; print(json.load(sys.stdin).get("access_token",""))'
        else
          # crude fallback
          echo "$resp" | sed -n 's/.*"access_token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
        fi
      }
    '';
  };

  home.packages = with pkgs; [
    pkgs.nixpkgs-collection.nixpkgs-stable.ansible
    ffmpeg
    colima
    lima
    yt-dlp
    graphviz
    binwalk
    imagemagick
    qemu

    (copier.overridePythonAttrs (prev: {
      dependencies =
        prev.dependencies
        ++ (with pkgs.python3.pkgs; [
          cookiecutter
        ]);
    }))

    (pkgs.writeScriptBin "wireshark" ''
      #!/bin/sh
      exec "/Applications/Wireshark.app/Contents/MacOS/Wireshark" "$@"
    '')

    # glib, gobject-introspection, harfbuzz, ldc, librsvg, lima, llvm, python-tk@3.12, qt@5 and yt-dlp
    #

    # ladybird
    # rustpython
    # (rustpython.withPackages (p: with p; [
    #   pydantic
    #   pydantic-settings
    # ])
    # )
  ];
}
