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
    file
  ] ++ [
    (pkgs.writeShellScriptBin
      "vscode-server-env-setup.sh"
      (builtins.readFile (./. + "/vscode-server-env-setup.sh"))
    )
  ];

  programs = {
    direnv.enable = true;
    gnupg.agent.enable = true;
  };

  wsl = {
    enable = true;
    defaultUser = "rubikoid";
    nativeSystemd = false;
    useWindowsDriver = true;

    wslConf = {
      network.generateResolvConf = false;
    };
  };

  # programs.nix-ld.enable = true;

  hardware.opengl.enable = lib.mkForce false;

  networking.nameservers = [
    "192.168.1.107"
  ];

  system.stateVersion = "24.05"; # Did you read the comment?
}
