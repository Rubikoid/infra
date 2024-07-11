pkgs: lib:
rec {
  # trace and return itself out
  strace = x: builtins.trace x x;

  # known magic from @balsoft flake.nix...
  # some function for <dir: path>
  findModules = dir:
    # magic
    builtins.concatLists (
      # magic
      builtins.attrValues (
        # apply first function to every elem of readdir
        builtins.mapAttrs
          (
            name: # filename
            type: # filetype: regular, directory, symlink, unknown

            # if just a simple file - remove .nix and add it to path
            if type == "regular" then
              if (builtins.match "(.*)\\.nix" name) != null then [{
                # but check, is it really .nix file...
                name = builtins.elemAt (builtins.match "(.*)\\.nix" name) 0;
                value = dir + "/${name}";
              }]
              else [ ]

            # if it directory
            else if type == "directory" then
              if (builtins.readDir (dir + "/${name}")) ? "default.nix" then [{
                # if contains default.nix - load it
                inherit name;
                value = dir + "/${name}";
              }]
              else
              # else just recursive load
                findModules (dir + "/${name}")
            else [ ]
          )
          (builtins.readDir dir)
      )
    );

  # read system for hostname
  # defaults to x86_64-linux
  readSystem = hostname:
    if
      builtins.pathExists (./hosts + "/${hostname}/system")
    then
      lib.removeSuffix "\n" (builtins.readFile (./hosts + "/${hostname}/system"))
    else
      "x86_64-linux";

  # simple predicate for darwin
  isDarwinFilter = hostname: lib.hasSuffix "-darwin" (readSystem hostname);

  # simple predicate for WSL ;)
  isWSLFilter = hostname: lib.hasSuffix "-wsl" hostname;

  # join strings by comma
  commaJoin = builtins.concatStringsSep ",";

  # i don't remember WTF is it ;(
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

  # i don't remember WTF is it too;(
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

  # Make docker network...
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
