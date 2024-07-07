{ pkgs, config, secrets, inputs, lib, ... }:

{
  imports = with inputs.self.systemModules; [
    hm
    yggdrasil

    # ca
    ca_rubikoid

    # other
    remote-build

    # users
    rubikoid
  ] ++ (with inputs.self.darwinModules; [
    tiling
    yggdrasil
  ]);

  environment.systemPackages = with pkgs; [
    nvd
  ];

  services.nix-daemon.enable = true;

  programs = {
    direnv.enable = true;
    zsh.enable = true;
  };

  networking = {
    computerName = config.device;
  };

  homebrew = {
    enable = true;

    global = {
      autoUpdate = false;
    };

    brews = [
      "far2l"
      "fzf"
      "python@3.10"
      "lunchy"
    ];

    casks = [
      "keepassxc"
      "stats"
    ];
  };

  security.pam.enableSudoTouchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
