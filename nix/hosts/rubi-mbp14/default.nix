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

  programs = {
    zsh.enable = true;
  };

  networking = {
    computerName = config.device;
  };

  system.primaryUser = "rubikoid";

  homebrew = {
    enable = true;

    global = {
      autoUpdate = false;
    };

    brews = [
      "far2l"
      "lunchy"
    ];

    casks = [
      "keepassxc"
      "stats"
      "jordanbaird-ice"
      "ghostty"
      "dbeaver-community"
    ];
  };

  services.tailscale.enable = false;

  security.pam.services.sudo_local.touchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
