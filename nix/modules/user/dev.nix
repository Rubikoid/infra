{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      nil
      nixfmt-rubi-style

      ripgrep

      # lazygit

      k9s
      kubectl
      krew
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

      git
      git-lfs

      # (pkgs.writeScriptBin "wireshark" ''
      #   #!/bin/sh
      #   exec "/Applications/Wireshark.app/Contents/MacOS/Wireshark" "$@"
      # '')
    ];

    sessionVariables = {
      RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
    };

    sessionPath = [
      "\${KREW_ROOT:-$HOME/.krew}/bin"
    ];
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
