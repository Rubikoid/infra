{
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;

    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      generateKey = false;
      # keyFile = "/home/rubikoid/.config/sops/age/keys.txt";
    };
  };

  sops.secrets."ssh/rubikoid/main" = { };
}
