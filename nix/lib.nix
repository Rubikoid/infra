pkgs: lib:
rec {
  commaJoin = builtins.concatStringsSep ",";
  mkSecrets =
    basePath: extraAttrs: paths:
    builtins.listToAttrs
      (map
        (
          pathName: {
            name = pathName;
            value = {
              sopsFile = basePath + "/${pathName}";
            } // extraAttrs;
          }
        )
        paths
      );

  mkBinarySecrets = basePath: extraAttrs: paths:
    mkSecrets
      basePath
      ({ format = "binary"; } // extraAttrs)
      paths;

  # stolen from https://github.com/NixOS/nixpkgs/blob/0c7ffbc66e6d78c50c38e717ec91a2a14e0622fb/nixos/lib/systemd-lib.nix#L264
  # since i can't find way to import it properly ;(
  shellEscape = s: (lib.replaceStrings [ "\\" ] [ "\\\\" ] s);

  makeJobScript = name: text:
    let
      scriptName = lib.replaceStrings [ "\\" "@" ] [ "-" "_" ] (shellEscape name);
      out = (pkgs.writeShellScriptBin scriptName ''
        set -e
        ${text}
      '').overrideAttrs (_: {
        # The derivation name is different from the script file name
        # to keep the script file name short to avoid cluttering logs.
        name = "unit-script-${scriptName}";
      });
    in
    "${out}/bin/${scriptName}";

  mkDockerNet = config: name:
    let
      net-name = "${name}-net";
    in
    {
      description = "Create the network bridge for ${name}.";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig.Type = "oneshot";
      script =
        let dockercli = "${config.virtualisation.docker.package}/bin/docker";
        in
        ''
          # ${net-name} network
          check=$(${dockercli} network ls | grep "${net-name}" || true)
          if [ -z "$check" ]; then
            ${dockercli} network create ${net-name}
          else
            echo "${net-name} already exists in docker"
          fi
        '';
    };
}
