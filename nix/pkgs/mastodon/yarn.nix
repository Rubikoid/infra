/*
Stolen from:
https://git.eisfunke.com/config/nixos/-/blob/2bfd28ad0d213b98b77ca330ece0bed5e1147e1b/packages/mastodon/yarn.nix
*/
{
  stdenvNoCC,
  yarn-berry,
  cacert,
  src,
  hash,
}:
stdenvNoCC.mkDerivation {
  name = "yarn-deps";
  nativeBuildInputs = [yarn-berry cacert];
  inherit src;
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
  outputHash = hash;
  outputHashMode = "recursive";
}
