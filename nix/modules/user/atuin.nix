{ secrets, config, ... }:
{
  sops.secrets."atuin" = {
    sopsFile = secrets.deviceSecrets + "/secrets.yaml";
    # mode = "0400";
  };

  programs.atuin = {
    enable = true;
    daemon.enable = true;

    settings = {
      workspaces = true;
      invert = true;

      style = "compact";

      filter_mode = "global";
      filter_mode_shell_up_key_binding = "session";

      key_path = config.sops.secrets."atuin".path;

      sync_address = "https://atuin.${secrets.dns.private}";
      sync_frequency = "10m";
      dialect = "uk";
      update_check = false;
    };

    flags = [ "--disable-up-arrow" ];

    enableZshIntegration = true;
  };
}
