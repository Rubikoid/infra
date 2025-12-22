inputs: final: prev: rec {
  mastodon-glitch = final.callPackage ./pkgs/mastodon/default.nix { };
  mongodb-ce = final.callPackage ./pkgs/mongodb-ce.nix { };
  openthread-border-router = final.callPackage ./pkgs/openthread-border-router { };
}
