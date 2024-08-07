/*
  Copied from nixpkgs upstream:
  https://github.com/NixOS/nixpkgs/blob/nixos-23.11/pkgs/servers/mastodon/default.nix

  Stolen from:
  https://git.eisfunke.com/config/nixos/-/blob/2bfd28ad0d213b98b77ca330ece0bed5e1147e1b/packages/mastodon/default.nix
*/

{ lib
, stdenv
, stdenvNoCC
, nodejs-slim
, bundlerEnv
, yarn-berry
, callPackage
, imagemagick
, ffmpeg
, file
, ruby
, writeShellScript
, brotli
, cacert
}:

let

  # optimally, updates only need to touch `version_data.nix`, and nothing else should be in there
  versionData = import ./version_data.nix;

  # use the first 7 characters of the glitch-soc commit hash as version string
  version = builtins.substring 0 7 versionData.rev;

  # the patched glitch-soc source
  src = callPackage ./source.nix { };

  # ruby gems, built from `gemset.nix`, which is generated by bundix in `update.sh` from the source Gemfile
  mastodonGems = bundlerEnv {
    name = "glitch-soc-gems-${version}"; # bundlerEnv breaks when pname is set instead
    inherit version ruby;
    gemset = ./gemset.nix;
    gemdir = src;
  };

  # fetches JS dependencies via yarn based on the lockfile in the source
  mastodonYarnDeps = stdenvNoCC.mkDerivation {
    pname = "glitch-soc-yarn-deps";
    inherit version src;

    nativeBuildInputs = [ yarn-berry cacert ];

    dontInstall = true;

    NODE_EXTRA_CA_CERTS = "${cacert}/etc/ssl/certs/ca-bundle.crt";

    buildPhase = ''
      mkdir -p $out

      export HOME=$(mktemp -d)
      echo $HOME

      export YARN_ENABLE_TELEMETRY=0
      export YARN_COMPRESSION_LEVEL=0

      cache="$(yarn config get cacheFolder)"
      yarn install --immutable --mode skip-build

      cp -r $cache/* $out/
    '';

    outputHashAlgo = "sha256";
    outputHash = versionData.yarnHash;
    outputHashMode = "recursive";
  };

  # builds the node modules for mastodon using the previously fetched yarn deps
  mastodonModules = stdenv.mkDerivation {
    pname = "glitch-soc-modules";
    inherit version src;

    yarnOfflineCache = mastodonYarnDeps;

    nativeBuildInputs = [ nodejs-slim yarn-berry brotli mastodonGems mastodonGems.wrappedRuby ];

    RAILS_ENV = "production";
    NODE_ENV = "production";

    /*
      So it seems that somehow a change in Linux 6.9 changed something that broke libuv, an IO lib
      used by Node. This undocumented env var disables the broken IO feature in libuv and it works
      again.

      - https://lore.kernel.org/lkml/d7003b6e-b8e3-41c4-9e6e-2b9abd0c5572@gmail.com/t/
      - https://github.com/nodejs/node/issues/53051#issuecomment-2124940205
      - https://github.com/nodejs/docker-node/issues/1912#issuecomment-1594233686
    */
    UV_USE_IO_URING = "0";

    buildPhase = ''
      runHook preBuild

      export HOME=$PWD
      # This option is needed for openssl-3 compatibility
      # Otherwise we encounter this upstream issue: https://github.com/mastodon/mastodon/issues/17924
      export NODE_OPTIONS=--openssl-legacy-provider

      export YARN_ENABLE_TELEMETRY=0
      mkdir -p ~/.yarn/berry
      ln -sf $yarnOfflineCache ~/.yarn/berry/cache

      # --inline-builds prints build logs inline so they can be inspected with nix log
      yarn install --immutable --immutable-cache --inline-builds

      patchShebangs ~/bin
      patchShebangs ~/node_modules

      # skip running yarn install
      rm -rf ~/bin/yarn

      OTP_SECRET=precompile_placeholder \
      SECRET_KEY_BASE=precompile_placeholder \
      ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=precompile_placeholder \
      ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=precompile_placeholder \
      ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=precompile_placeholder \
        rails assets:precompile

      yarn cache clean
      rm -rf ~/node_modules/.cache

      # Create missing static gzip and brotli files
      gzip --best --keep ~/public/assets/500.html
      gzip --best --keep ~/public/packs/report.html
      find ~/public/assets -maxdepth 1 -type f -name '.*.json' \
        -exec gzip --best --keep --force {} ';'
      brotli --best --keep ~/public/packs/report.html
      find ~/public/assets -type f -regextype posix-extended -iregex '.*\.(css|js|json|html)' \
        -exec brotli --best --keep {} ';'

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/public
      cp -r node_modules $out/node_modules
      cp -r public/assets $out/public
      cp -r public/packs $out/public

      runHook postInstall
    '';
  };

  # the actual main glitch-soc package

in
stdenv.mkDerivation {

  pname = "glitch-soc";
  inherit version src mastodonGems mastodonModules;

  propagatedBuildInputs = [ mastodonGems.wrappedRuby ];
  nativeBuildInputs = [ brotli ];
  buildInputs = [ mastodonGems nodejs-slim ];

  buildPhase = ''
    runHook preBuild

    ln -s $mastodonModules/node_modules node_modules
    ln -s $mastodonModules/public/assets public/assets
    ln -s $mastodonModules/public/packs public/packs

    patchShebangs bin/
    for b in $(ls $mastodonGems/bin/)
    do
      if [ ! -f bin/$b ]; then
        ln -s $mastodonGems/bin/$b bin/$b
      fi
    done

    # Remove execute permissions
    chmod 0444 public/emoji/*.svg

    # Create missing static gzip and brotli files
    find public -maxdepth 1 -type f -regextype posix-extended -iregex '.*\.(css|js|svg|txt|xml)' \
      -exec gzip --best --keep --force {} ';' \
      -exec brotli --best --keep {} ';'
    find public/emoji -type f -name '.*.svg' \
      -exec gzip --best --keep --force {} ';' \
      -exec brotli --best --keep {} ';'
    ln -s assets/500.html.gz public/500.html.gz
    ln -s assets/500.html.br public/500.html.br
    ln -s packs/sw.js.gz public/sw.js.gz
    ln -s packs/sw.js.br public/sw.js.br
    ln -s packs/sw.js.map.gz public/sw.js.map.gz
    ln -s packs/sw.js.map.br public/sw.js.map.br

    rm -rf log
    ln -s /var/log/mastodon log
    ln -s /tmp tmp

    runHook postBuild
  '';

  installPhase =
    let
      run-streaming = writeShellScript "run-streaming.sh" ''
        # NixOS helper script to consistently use the same NodeJS version the package was built with.
        ${nodejs-slim}/bin/node ./streaming
      '';
    in
    ''
      runHook preInstall

      mkdir -p $out
      cp -r * $out/
      ln -s ${run-streaming} $out/run-streaming.sh

      runHook postInstall
    '';

}
