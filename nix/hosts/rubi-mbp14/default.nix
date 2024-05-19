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
      "age"
      "ansible"
      "far2l"
      "fzf"
      "python@3.10"
      "lunchy"
    ];

    casks = [
      "keepassxc"
    ];
  };

  security.pam.enableSudoTouchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
