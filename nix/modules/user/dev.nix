{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nil
    nixfmt-rubi-style

    ripgrep

    # lazygit

    k9s
    kubectl
    kubecm
    kustomize

    bat

    whois
    ldns

    glab
    jq
    yq
    skopeo

    # inetutils
    # i fucking hate gnu
    ldns

    far2l

    openssl

    cargo
    rustc
    rust-analyzer
    clippy

    mergiraf
  ];

  home.sessionVariables = {
    RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
  };

  programs.lazygit = {
    enable = true;
    settings = {
      customCommands = [
        {
          key = "p";
          context = "global";
          command = "git pull --rebase --autostash -v";
          description = "GUPAV:";
        }
      ];
    };
  };
}
