#!/usr/bin/env nix 
#! nix shell nixpkgs#coreutils nixpkgs#bundix nixpkgs#nix-prefetch-github nixpkgs#jq -c bash

set -e

cd "$(dirname "$0")"  # cd to the script's directory

echo "Retrieving latest glitch-soc commit..."
commit="$(curl -SsL 'https://api.github.com/repos/glitch-soc/mastodon/branches/main')"
rev="$(jq -r '.commit.sha' <<<"$commit")"
echo "Latest commit is $rev."

echo
echo "Prefetching source..."
hash="$(nix-prefetch-github glitch-soc mastodon --rev "$rev" | jq -r '.hash')"

echo
echo "Generating version_data.nix..."
cat > version_data.nix << EOF
# This file was generated with update.sh.
{
  rev = "$rev";
  hash = "$hash";
  yarnHash = "";
}
EOF

echo
echo "Building source derivation..."
srcdir="$(nix build --no-link --print-out-paths --no-warn-dirty ../..#glitch-soc-source)"
echo "Source derivation is $srcdir."

echo
echo "Generating gemset.nix using built source derivation..."
rm -f gemset.nix
bundix --quiet --lockfile $srcdir/Gemfile.lock --gemfile $srcdir/Gemfile
echo "" >> gemset.nix

echo
echo "Done."

echo
echo "You'll have to manually enter the commit hash for the yarn deps from the error message when first trying to build the package."
