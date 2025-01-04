{
  pkgs,
  lib,
  secrets,
  isDarwin,
  isWSL,
  ...
}:
{
  imports = [
    (if isDarwin then ./darwin.nix else { })
    (if isWSL then ./wsl.nix else { })
  ];

  home = {
    sessionVariables = {
      CODESTATS_API_KEY = secrets.codestats.zsh;
    };

    shellAliases = { };
  };

  # because of i don't fucking know, to make this work properly, you SHOULD
  # programs.zsh.enable = true; in your NIXOS config (system.zsh module in my case)
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;

    # zprof.enable = true;

    initExtra = ''
      get_path_from_old_shell() {
          # chpwd() {
          #     export SHORT_PWD=
          # }

          SHORT_PWD_DUMP_PATH="/tmp/short_pwd_dump"
          
          TRAPUSR1() {
              # echo "$SHORT_PWD" > /tmp/short_pwd_dump
              print -rD $PWD > $SHORT_PWD_DUMP_PATH
          }

          load_old_path() {
              # kill -USR1 $(ps u | grep $(echo "$SOURCE_PANE_TTY" | awk -F/ '{print $3 "/" $4;}') | awk '/\-zsh$/{print $2; }')
              if [[ -n "$SOURCE_PANE_PID" ]]; then
                  kill -USR1 "$SOURCE_PANE_PID";sleep 0.1;
                  KILL_STATUS=$?;
                  if [[ -e "$SHORT_PWD_DUMP_PATH" ]]; then 
                      echo "Source pid=$SOURCE_PANE_PID; path=$(cat "$SHORT_PWD_DUMP_PATH")"
                      eval cd $(cat "$SHORT_PWD_DUMP_PATH") && \
                      rm "$SHORT_PWD_DUMP_PATH"
                  else
                      echo "Source pid=$SOURCE_PANE_PID; no file at '$SHORT_PWD_DUMP_PATH' "
                  fi;
              fi;
          }
      }
    '';

    initExtraBeforeCompInit = "";

    oh-my-zsh = {
      enable = true;
      theme = lib.mkDefault "candy";
      plugins = lib.mkMerge [
        [
          "git"
          # "docker"
        ]
        (lib.mkIf (!isDarwin) [
          "systemd"
        ])
      ];
    };

    zplug = {
      enable = true;
      plugins = [
        {
          # copypasted from https://github.com/vvarma/dotfiles/blob/2bd902aba970f1a5e9eb3ee97cb9b6f14f95c276/nix/modules/common/zsh.nix#L22
          name = "code-stats/code-stats-zsh";
          tags = [
            "from:gitlab"
            "use:codestats.plugin.zsh"
          ];
        }
      ];
    };
  };
}
