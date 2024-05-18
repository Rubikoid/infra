{ pkgs, secrets, ... }:
{
  programs.helix = {
    enable = true;
    defaultEditor = true;

    extraPackages = with pkgs; [
      # 
    ];

    languages = { };

    settings = {
      theme = "github_dark_dimmed";
      keys.normal.g = {
        left = "goto_line_start";
        right = "goto_line_end";
      };
      codestats.key = secrets.codestats.helix;
    };
  };
}
