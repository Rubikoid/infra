{ secrets, config, ... }:
{
  programs.pay-respects = {
    enable = true;
    enableZshIntegration = true;

    options = [ ];
  };

  xdg.configFile."pay-respects/config.toml".text = ''
    [package_manager]
    package_manager = "nix"
    install_method = "Shell"
  '';
}
