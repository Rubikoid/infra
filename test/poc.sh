#!/usr/bin/env bash

# nix run nixpkgs#bat poc.sh
nix run nixpkgs#bat test.nix

# echo "List autoconf"
# ls /nix/store/ | grep -P 'autoconf-[\.\d.]*\.drv'
# echo ""

# echo "Check for 2.70"
# ls /nix/store/ | grep -P 'autoconf-[\.\d.]*\.drv' | grep '2.70'

echo ""
rm -rf ./result || true

echo "Build"
nix-build test.nix

ls -la .

echo "Run..."
result/bin/autoconf -V
