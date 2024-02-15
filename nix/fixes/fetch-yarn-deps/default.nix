inputs: final: prev:
let
  yarnpkg-lockfile-tar = prev.fetchurl {
    url = "https://registry.yarnpkg.com/@yarnpkg/lockfile/-/lockfile-1.1.0.tgz";
    hash = "sha512-GpSwvyXOcOOlV70vbnzjj4fW5xW/FdUF6nQEt1ENy7m4ZCczi1+/buVUPAqmGfqznsORNFzUMjctTIp8a9tuCQ==";
  };

  inherit (final) stdenv lib;
in
rec {
  prefetch-yarn-deps = prev.prefetch-yarn-deps.overrideAttrs (old: {
    buildPhase = ''
      runHook preBuild

      mkdir libexec
      tar --strip-components=1 -xf ${yarnpkg-lockfile-tar} package/index.js
      mv index.js libexec/yarnpkg-lockfile.js
      cp ${./.}/*.js libexec/
      patchShebangs libexec

      runHook postBuild
    '';
  });

  # fetchYarnDeps =
  fetchYarnDeps =
    let
      f =
        { name ? "offline"
        , src ? null
        , hash ? ""
        , sha256 ? ""
        , ...
        }@args:
        let
          hash_ =
            if hash != "" then { outputHashAlgo = null; outputHash = hash; }
            else if sha256 != "" then { outputHashAlgo = "sha256"; outputHash = sha256; }
            else { outputHashAlgo = "sha256"; outputHash = lib.fakeSha256; };
        in
        stdenv.mkDerivation ({
          inherit name;

          dontUnpack = src == null;
          dontInstall = true;

          nativeBuildInputs = [ prefetch-yarn-deps final.cacert ];
          GIT_SSL_CAINFO = "${final.cacert}/etc/ssl/certs/ca-bundle.crt";
          NODE_EXTRA_CA_CERTS = "${final.cacert}/etc/ssl/certs/ca-bundle.crt";

          buildPhase = ''
            runHook preBuild

            yarnLock=''${yarnLock:=$PWD/yarn.lock}
            mkdir -p $out
            (cd $out; prefetch-yarn-deps --verbose --builder $yarnLock)

            runHook postBuild
          '';

          outputHashMode = "recursive";
        } // hash_ // (removeAttrs args [ "src" "name" "hash" "sha256" ]));

    in
    lib.setFunctionArgs f (lib.functionArgs f) // {
      # inherit tests;
    };
}
