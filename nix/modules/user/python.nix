{ pkgs, secrets, ... }:
{
  home.packages =
    let
      python = pkgs.python312;
    in
    with pkgs; [
      # python tools
      uv # install packages
      ruff # linter-checker
      # ruff-lsp # linter-checker, but as LSP
      basedpyright # pyright, but on steroids
      pylyzer # yes, it is another LSP

      # python itself with some default libs
      (python.withPackages (ps:
        (with ps; [
          pip
          # dev packages, that i need usually on random project
          pydantic
          pydantic-settings
          fastapi
          rich
          typer
          aiohttp
          orjson
          requests
          loguru
          cyclopts
          # etc
          python-lsp-server # yes, it is another lsp.
        ])
        ++
        (with pkgs; [

        ])
      ))

      # poetry... because... idk
      # (poetry.override { python3 = python; })
    ];

  programs.ruff = {
    enable = true;
    settings = {
      # 80 chars limit isn't enough in 21 century
      line-length = 120;

      # @profile just makes me cry 
      builtins = [ "profile" ];

      # don't poison local dirs please
      cache-dir = "~/.cache/ruff";

      # no thanks, i can fix it myself
      fix = false;

      target-version = "py312";

      lint = {
        # task tags
        task-tags = [ "TODO" "FIXME" "WTF" "XXX" ];

        # rules...
        select = [ "ALL" ];

        ignore = [
          # Ignored #   | plugin name           | Description                                                       # Why it is ignored
          #
          # "ANN401" #  | flake8-annotations      | Dynamically typed expressions (Any) are disallowed                # i knew.
          #
          "D100" #    | pydocstyle              | Missing docstring in public module                                # well, i know, where i should and shoul't write docs 
          "D101" #    | pydocstyle              | Missing docstring in public class                                 # well, i know, where i should and shoul't write docs 
          "D102" #    | pydocstyle              | Missing docstring in public method                                # well, i know, where i should and shoul't write docs 
          "D103" #    | pydocstyle              | Missing docstring in public function                              # well, i know, where i should and shoul't write docs 
          "D104" #    | pydocstyle              | Missing docstring in public package                               # well, i know, where i should and shoul't write docs 
          "D105" #    | pydocstyle              | Missing docstring in magic method                                 # well, i know, where i should and shoul't write docs 
          "D106" #    | pydocstyle              | Missing docstring in public nested class                          # well, i know, where i should and shoul't write docs 
          #
          "D212" #    | pydocstyle              | multi-line-summary-second-line                                    # i prefer docs on second lines
          #
          "F401" #    | pyflakes                | %r imported but unused                                            # pylance cover it
          "TID252" #  | flake8-tidy-imports     | Relative imports are banned                                       # i love relative imports
        ];
      };
    };
  };
}
