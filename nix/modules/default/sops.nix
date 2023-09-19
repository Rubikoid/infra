{
  imports = [ <sops-nix/modules/sops> ];
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;

    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/home/rubikoid/.config/sops/age/keys.txt";
      generateKey = false;
    };
  };
}
