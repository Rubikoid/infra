{ secrets, config, ... }:
{
  programs.pay-respects = {
    enable = true;
    enableZshIntegration = true;

    options = [ ];
  };
}
