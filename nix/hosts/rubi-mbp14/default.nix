{
  pkgs,
  config,
  secrets,
  inputs,
  lib,
  ...
}:

{
  imports = lib.lists.flatten (
    with lib.r.modules;
    [
      (with system; [
        hm
        yggdrasil

        dev.direnv
        ca.rubikoid
        users.rubikoid

        (with other; [
          remote-build
        ])
      ])
      (with darwin; [
        tiling
        yggdrasil
        gc-debug
      ])
    ]
  );

  environment.systemPackages = with pkgs; [
    nvd
  ];

  services.nix-daemon.enable = true;

  programs = {
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
      "ghostty"
    ];
  };

  services.tailscale.enable = false;

  security.pam.enableSudoTouchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
