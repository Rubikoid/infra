inputs: final: prev: rec {
  mastodon-glitch = final.callPackage ./pkgs/mastodon/default.nix { };
  mongodb-ce = final.callPackage ./pkgs/mongodb-ce.nix { };
  openthread-border-router = final.callPackage ./pkgs/openthread-border-router { };

  curlSuckless = prev.curl.override {
    http3Support = false;
    c-aresSupport = false;
  };

  nix = prev.nix.override {
    nix-store = prev.nix.libs.nix-store.override {
      curl = final.curlSuckless;
      withAWS = false;
    };

    nix-fetchers = prev.nix.libs.nix-fetchers.override {
      nix-store = final.nix.libs.nix-store;
    };

    nix-expr = prev.nix.libs.nix-expr.override {
      nix-store = final.nix.libs.nix-store;
      nix-fetchers = final.nix.libs.nix-fetchers;
    };

    nix-main = prev.nix.libs.nix-main.override {
      nix-store = final.nix.libs.nix-store;
      nix-expr = final.nix.libs.nix-expr;
    };

    nix-flake = prev.nix.libs.nix-flake.override {
      nix-store = final.nix.libs.nix-store;
      nix-fetchers = final.nix.libs.nix-fetchers;
      nix-expr = final.nix.libs.nix-expr;
    };

    nix-cmd = prev.nix.libs.nix-cmd.override {
      nix-store = final.nix.libs.nix-store;
      nix-fetchers = final.nix.libs.nix-fetchers;
      nix-expr = final.nix.libs.nix-expr;
      nix-flake = final.nix.libs.nix-flake;
      nix-main = final.nix.libs.nix-main;
    };

    nix-cli = prev.nix.nix-cli.override {
      nix-store = final.nix.libs.nix-store;
      nix-expr = final.nix.libs.nix-expr;
      nix-main = final.nix.libs.nix-main;
      nix-cmd = final.nix.libs.nix-cmd;
    };
  };

}
