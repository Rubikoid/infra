{ pkgs, ... }:

{
  programs.zsh = {
    interactiveShellInit = ''
      export FZF_BASE_PATH=${pkgs.fzf}/

      alias tmux="tmux attach || tmux"
    '';
    ohMyZsh = {
      theme = "candy";
      plugins = [
        "git"
        "systemd"
        "docker"
      ];
    };
  };
}
