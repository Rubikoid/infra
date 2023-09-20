{ inputs, ... }:

{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;

    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      generateKey = false;
      # keyFile = "/home/rubikoid/.config/sops/age/keys.txt";
    };
  };

}
