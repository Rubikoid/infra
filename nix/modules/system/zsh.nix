{ pkgs, ... }:

{
  environment.shells = with pkgs; [ zsh ];

  # zsh
  programs.zsh = {
    enable = true;

    # TODO: make this properly
    # inject omz path
    interactiveShellInit = ''
      # zsh.nix appending
      export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh
      export FZF_BASE_PATH=${pkgs.fzf}/
    '';
    promptInit = "";

    ohMyZsh = {
      enable = true;
    };
  };

  users.defaultUserShell = pkgs.zsh;
}
