# This shell script is run before checking for vscode version updates.
# If a newer version is downloaded, this script won't patch that version,
# resulting in error. Therefore retry is required to patch it.

echo "== '$0' SCRIPT START =="

# This shell script uses nixpkgs branch from OS version.
# If you want to change this behavior, change environment variable below.
#   e.g. NIXOS_VERSION=unstable
NIXOS_VERSION=$(nixos-version | cut -d "." -f1,2)
echo "NIXOS_VERSION detected as \"$NIXOS_VERSION\""

PKGS_EXPRESSION=n#pkgs

# Get directory where this shell script is located
VSCODE_SERVER_DIR="/home/rubikoid/.vscode-server"
echo "Got vscode directory: \"$VSCODE_SERVER_DIR\" (from \"$RAW_VSCODE_SERVER_DIR\")"
echo "If the directory is incorrect, you can hardcode it on the script."

echo "Patching nodejs binaries..."
nix shell $PKGS_EXPRESSION.patchelf $PKGS_EXPRESSION.stdenv.cc -c bash -c "
    NIX_INTERPRETER=\"\$(cat \$(nix eval --raw $PKGS_EXPRESSION.stdenv.cc)/nix-support/dynamic-linker)\"
    NIX_RPATH=\"\$(nix eval --raw $PKGS_EXPRESSION.stdenv.cc.cc.lib)/lib/\"
    
    for versiondir in $VSCODE_SERVER_DIR/bin/*/; do
        # Currently only "libstdc++.so.6" needs to be patched
        patchelf --set-interpreter \"\$NIX_INTERPRETER\" --set-rpath \"\$NIX_RPATH\" \"\$versiondir\"\"node_modules/node-pty/build/Release/pty.node\"
        patchelf --set-interpreter \"\$NIX_INTERPRETER\" --set-rpath \"\$NIX_RPATH\" \"\$versiondir\"\"node\"
    done
"

echo "== '$0' SCRIPT END =="
