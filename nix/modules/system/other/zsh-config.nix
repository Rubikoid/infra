{ pkgs, lib, ... }:

{
  programs.zsh = {
    interactiveShellInit = ''
      export FZF_BASE_PATH=${pkgs.fzf}/

      alias tmux="tmux attach || tmux"
    '';
    ohMyZsh = {
      theme = lib.mkDefault "candy";
      plugins = [
        "git"
        "systemd"
        "docker"
      ];
    };
  };
}
