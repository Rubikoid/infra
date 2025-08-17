{ secrets, config, ... }:
{
  # sops.secrets."atuin" = {
  #   sopsFile = secrets.deviceSecrets + "/secrets.yaml";
  #   # mode = "0400";
  # };

  programs.atuin = {
    enable = true;
    daemon.enable = if config.user != "root" then true else false;

    settings = {
      workspaces = true;
      invert = true;

      style = "compact";

      filter_mode = "global";
      filter_mode_shell_up_key_binding = "session";

      secrets_filter = false;

      # WTF: atuin have cringe imperative shit
      # https://github.com/atuinsh/atuin/issues/2479#issuecomment-2528215934
      # key_path = config.sops.secrets."atuin".path;

      sync.records = true;
      auto_sync = true;
      sync_frequency = "10m";
      sync_address = "https://atuin.${secrets.dns.private}";

      dialect = "uk";
      update_check = false;
    };

    flags = [ "--disable-up-arrow" ];

    enableZshIntegration = true;
  };
}
