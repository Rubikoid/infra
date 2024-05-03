{ pkgs, config, secrets, inputs, lib, ... }:

{
  imports = with inputs.self.systemModules; [
    zsh
    zsh-config

    # ca
    ca_rubikoid
  ];

  environment.systemPackages = with pkgs; [
    bash
    vim
  ] ++ [
    (pkgs.writeShellScriptBin
      "vscode-server-env-setup.sh"
      (builtins.readFile (./. + "/vscode-server-env-setup.sh"))
    )
  ];

  wsl = {
    enable = true;
    defaultUser = "rubikoid";
    nativeSystemd = false;

    wslConf = {
      network.generateResolvConf = false;
    };
  };

  networking.nameservers = [
    "192.168.1.107"
  ];

  nixpkgs.hostPlatform = lib.mkDefault config.system-arch-name;
  system.stateVersion = "24.05"; # Did you read the comment?
}
