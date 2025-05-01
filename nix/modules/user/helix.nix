{ pkgs, secrets, ... }:
{
  programs.helix = {
    enable = true;
    defaultEditor = true;

    extraPackages = with pkgs; [
      #
    ];

    languages = {
      language-server.pyright = {
        command = "basedpyright-langserver";
        config = {
          lint = true;
          "inlayHint.enable" = true;
        };
      };

      language-server.ruff = {
        command = "ruff";
        args = [
          "server"
          "--preview"
        ];
      };

      language =
        let
          gen = lang: extra: { name = lang; } // extra;

          genCS =
            lang: cs: extra:
            gen lang ({ codestats = cs; } // extra);

          genC = lang: cs: genCS lang cs { };
        in
        [
          (gen "nix" {
            formatter = {
              command = "${pkgs.nixfmt-rubi-style}/bin/nixfmt";
              args = [ ];
            };
          })
          (gen "markdown" {
            soft-wrap.enable = true;
          })
          (gen "python" {
            auto-format = true;
            rulers = [ 120 ];
            language-servers = [
              # {
              #   name = "pylsp";
              #   except-features = [ ];
              #   # only-features = [ ];
              # }
              {
                name = "pyright";
                except-features = [ ];
                # only-features = [ ];
              }
              # {
              #   name = "pylyzer";
              #   except-features = [ ];
              #   # only-features = [ ];
              # }
              {
                name = "ruff";
                except-features = [ ];
                # only-features = [ ];
              }
            ];
          })
          (genC "haskell" "Haskell")
          (genC "c" "C")
          (genC "php" "PHP")
          (genC "sql" "SQL")
          (genC "dockerfile" "Docker")
          # (genC "git-ignore" "")
        ];
    };

    settings = {
      # Setup theme
      theme = "github_dark_dimmed";

      # setup some editor settings
      editor = {
        # hate this shit.
        middle-click-paste = false;

        # great thing! works... maybe, if terminal looses focus
        auto-save = true;

        # i think... i need that?
        # this replaces with completion entire word, not only... part of it.
        completion-replace = true;

        # always display kinda tabs at top
        bufferline = "always";

        # not 80, because we in 21 centry
        text-width = 120;

        # LF EVERYTHERE
        # NO CRLF I HATE THAT SHIT
        default-line-ending = "lf";

        # borders, why not ?
        popup-border = "all";

        # setup few lsp things
        lsp = {
          # nice shit i think...
          display-inlay-hints = true;
        };
      };

      keys.normal."C-g" = [
        ":new"
        ":insert-output ${pkgs.lazygit}/bin/lazygit"
        ":buffer-close!"
        ":redraw"
      ];

      # Make use of g+{left, right} in normal mode
      # in vim this was ^$, but... here no, and this is better
      keys.normal.g = {
        left = "goto_line_start";
        right = "goto_line_end";
      };

      # same shit for visual mode
      keys.select.g = {
        left = "goto_line_start";
        right = "goto_line_end";
      };

      # save on ctrl+s...
      keys.normal."C-s" = ":w";

      # Put codestats key
      codestats.key = secrets.codestats.helix;
    };
  };
}
