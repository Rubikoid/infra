{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nil
    nixpkgs-fmt

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
