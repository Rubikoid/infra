{ pkgs, config, secrets, inputs, lib, ... }:

{
  imports = with inputs.self.systemModules; [
    ca_rubikoid
  ];

  environment.systemPackages = with pkgs; [
    # asd
  ];

  services.nix-daemon.enable = true;
  programs.zsh.enable = true;

  networking = {
    computerName = config.device;
  };

  security.pam.enableSudoTouchIdAuth = true;


  # serivce things
  nixpkgs.hostPlatform = lib.mkDefault config.system-arch-name;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
