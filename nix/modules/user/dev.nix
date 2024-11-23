{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nil
    nixfmt-rubi-style

    ripgrep

    # lazygit

    k9s
    kubectl
    
    bat

    whois
    ldns

    glab
    jq

    inetutils
    ldns

    far2l

    openssl
  ];

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
