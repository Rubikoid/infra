{
  pkgs,
  lib,
  secrets,
  isDarwin,
  ...
}:
{
  home = {
    sessionVariables = { };

    shellAliases = {
      diec = "/Applications/die.app/Contents/MacOS/diec";
      scli = "pbcopy";
      gcli = "pbpaste";
      far = "open -a /opt/homebrew/bin/far2l";
    };
  };

  programs.zsh = {
    initContent = lib.mkOrder 550 ''
      # zsh autocomplit from homebrew
      fpath+=/opt/homebrew/share/zsh/site-functions
    '';

    oh-my-zsh = {
      plugins = [
        "macos"
      ];
    };
  };
}
