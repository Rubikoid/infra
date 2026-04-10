{ ... }:
{
  programs.ghostty = {
    enable = true;

    # on macos ghostty comes from brew cask ;p
    package = null;

    settings = {
      window-inherit-working-directory = false;
      tab-inherit-working-directory = false;
      split-inherit-working-directory = true;
    };

    enableZshIntegration = true;
  };
}
