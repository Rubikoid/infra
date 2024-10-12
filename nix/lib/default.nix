inputs: _raw_lib:
let
  lib_result = _raw_lib.extend (
    lib: prev: {
      r = lib.makeExtensible (
        self:
        let
          _empty_list = [ ];

          loadFile =
            file:
            import file {
              inherit inputs lib;
              r = self;
            };
        in
        {
          # join strings by comma
          commaJoin = builtins.concatStringsSep ",";

          # known magic from @balsoft flake.nix...
          # some function for <dir: path>
          findModules =
            dir:
            # magic
            builtins.concatLists (
              # magic
              builtins.attrValues (
                # apply first function to every elem of readdir
                builtins.mapAttrs (
                  name:
                  # filename
                  type:
                  # filetype: regular, directory, symlink, unknown
                  # if just a simple file - remove .nix and add it to path
                  if type == "regular" then
                    if (builtins.match "(.*)\\.nix" name) != null then
                      [
                        {
                          # but check, is it really .nix file...
                          name = builtins.elemAt (builtins.match "(.*)\\.nix" name) 0;
                          value = dir + "/${name}";
                        }
                      ]
                    else
                      _empty_list
                  # if it directory
                  else if type == "directory" then
                    if (builtins.readDir (dir + "/${name}")) ? "default.nix" then
                      [
                        {
                          # if contains default.nix - load it
                          inherit name;
                          value = dir + "/${name}";
                        }
                      ]
                    else
                      # else just recursive load
                      self.findModules (dir + "/${name}")
                  else
                    _empty_list
                ) (builtins.readDir dir)
              )
            );

          # i don't remember WTF is it ;(
          mkSecrets =
            basePath: extraAttrs: paths:
            builtins.listToAttrs (
              map (pathName: {
                name = pathName;
                value = {
                  sopsFile = basePath + "/${pathName}";
                } // extraAttrs;
              }) paths
            );

          # i don't remember WTF is it too;(
          mkBinarySecrets =
            basePath: extraAttrs: paths:
            self.mkSecrets basePath ({ format = "binary"; } // extraAttrs) paths;

          # stolen from https://github.com/NixOS/nixpkgs/blob/0c7ffbc66e6d78c50c38e717ec91a2a14e0622fb/nixos/lib/systemd-lib.nix#L264
          # since i can't find way to import it properly ;(
          shellEscape = s: (lib.replaceStrings [ "\\" ] [ "\\\\" ] s);

          makeJobScript =
            pkgs: name: text:
            let
              scriptName =
                lib.replaceStrings
                  [
                    "\\"
                    "@"
                  ]
                  [
                    "-"
                    "_"
                  ]
                  (self.shellEscape name);
              out =
                (pkgs.writeShellScriptBin # fmt
                  scriptName # fmt
                  ''
                    set -e
                    ${text}
                  ''
                ).overrideAttrs
                  (_: {
                    # The derivation name is different from the script file name
                    # to keep the script file name short to avoid cluttering logs.
                    name = "unit-script-${scriptName}";
                  });
            in
            "${out}/bin/${scriptName}";

          # Make docker network...
          mkDockerNet =
            config: name:
            let
              net-name = "${name}-net";
            in
            {
              description = "Create the network bridge for ${name}.";
              after = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig.Type = "oneshot";
              script =
                let
                  dockercli = "${config.virtualisation.docker.package}/bin/docker";
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

          debug = loadFile ./debug.nix;
          merge = loadFile ./merge.nix;
          system = loadFile ./system;

          inherit (self.debug) strace straceSeq straceSeqN;
          inherit (self.merge) recursiveMerge mkMergeTopLevel;
          inherit (self.system)
            supportedSystems
            rawReadSystem
            readSystem
            isDarwinFilter
            isWSLFilter
            getHostOptions
            findAllHosts
            forEachHost
            rawPkgsFor
            rawForEachSystem
            modules
            nixosConfigGenerator
            rawMkSystem
            nixInit
            pkgsFor
            forEachSystem
            mkSystem
            ;
        }
      );
    }
  );
in
lib_result
