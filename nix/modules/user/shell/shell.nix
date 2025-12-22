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

    initContent =
      let
        rg = "${pkgs.ripgrep}/bin/rg";
      in
      ''
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

        # https://grok.com/share/c2hhcmQtNA_f0b60a6e-a29f-4936-9703-acf83c76a786
        magic_replace() {
          # Check arguments
          if [[ $# -ne 2 ]]; then
              echo "Usage: magic_replace <search> <replace>"
              echo "Example: magic_replace XXX NEWVALUE"
              return 1
          fi
          
          local search="$1"
          local replace="$2"

          # Find files containing the string (respecting .gitignore by default)
          local files=()
          while IFS= read -r file; do
              files+=("$file")
          done < <(${rg} -l -F --hidden "$search" 2>/dev/null)

          local count=''${#files[@]};

          if [[ $count -eq 0 ]]; then
            echo "No files found containing '$search'"
            return 0
          fi

          echo "Found '$search' in $count file(s):"
          printf '  %s\n' "''${files[@]}"

          # Confirmation prompt (y/n, default y)
          echo -n "Replace '$search' → '$replace' in the above files? [Y/n] "
          read -q answer || { echo "\nAborted."; return 0 }
          echo    # newline after the invisible keypress
          
          answer=''${answer:-y}  # default to yes if empty
          case "$answer" in
              [Yy]*|"") ;;
              [Nn]*) echo "Aborted."; return 0 ;;
              *) echo "Please answer y or n"; return 1 ;;
          esac

          # Perform the replacement
          echo "Replacing..."

          printf '%s\0' "''${files[@]}" | xargs -0 ${pkgs.perl}/bin/perl -i -pe "s/\Q$search\E/$replace/g" && \
          echo "Done! Replaced in $count file(s)." || \
          echo "Something went wrong!"
        }
      '';

    plugins = [
      {
        name = "fast-syntax-highlighting";
        src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
      }
      {
        name = "zsh-autosuggestions";
        src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "you-should-use";
        inherit (pkgs.zsh-you-should-use) src;
      }
    ];

    oh-my-zsh = {
      enable = true;
      theme = lib.mkDefault "candy";
      plugins = lib.mkMerge [
        [
          "git"
          # "docker"
          # "cmdtime"
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
