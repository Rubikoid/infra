{ pkgs, config, secrets, inputs, lib, ... }:

{
  imports = with lib.r.modules.system; [
    hm
    yggdrasil

    # ca
    ca_rubikoid

    # other
    remote-build

    # users
    rubikoid
  ] ++ (with lib.r.modules.darwin; [
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
      "jordanbaird-ice"
    ];
  };

  services.tailscale.enable = false;

  security.pam.enableSudoTouchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
