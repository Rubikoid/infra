{ pkgs, config, secrets, inputs, lib, ... }:

{
  imports = with inputs.self.systemModules; [
    ca_rubikoid
  ];

  environment.systemPackages = with pkgs; [
    yabai
    skhd
  ];

  services.nix-daemon.enable = true;
  programs.zsh.enable = true;

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
    ];

    casks = [
      "keepassxc"
    ];
  };

  services.yabai = {
    enable = true;

    # copypaste from yabairc
    config = {
      # global settings
      # focus window that your mouse hovers on (disabled due to right click bugs)
      focus_follows_mouse = "off";

      # move mouse to focused window
      mouse_follows_focus = "off";
      window_placement = "second_child";

      # floating windows always stay on top
      window_topmost = "on";

      # enable borders
      window_border = "off";

      # no clue what this is
      insert_feedback_color = "0xffd75f5f";
      split_ratio = "0.50";

      # don't automatically rebalance windows
      auto_balance = "off";

      # swap windows if moved with mouse
      mouse_action1 = "move";

      # resize windows if resized with mouse
      mouse_action2 = "resize";
      mouse_drop_action = "swap";

      # general space settings
      layout = "stack";
      top_padding = 2;
      bottom_padding = 2;
      left_padding = 2;
      right_padding = 2;
      window_gap = 1;
    };

    extraConfig = ''
      yabai -m rule --add app='^Mail$' title!='^Inbox – ' manage=off grid='4:4:1:1:2:2'
      yabai -m rule --add app='System Settings'  manage=off grid='4:4:1:1:2:2'
      yabai -m rule --add app='wine-preloader'  manage=off
      yabai -m rule --add app='Spyglass'  manage=off
      yabai -m rule --add app='DiE'  manage=off
    '';
  };

  services.skhd = {
    enable = true;

    skhdConfig = ''
      # Float and center window
      ctrl + shift + alt - c  : yabai -m window --toggle float;\
                                yabai -m window --grid 4:4:1:1:2:2

      # Float / Unfloat window
      ctrl + shift + alt - f  : yabai -m window --toggle float

      # Make stacking
      ctrl + shift + alt - s  : yabai -m space --layout stack

      # Make bsp
      ctrl + shift + alt - b  : yabai -m space --layout bsp

      # Make ???
      ctrl + alt - 1      : yabai -m window --display 1
      ctrl + alt - 2      : yabai -m window --display 2
      ctrl + alt - 3      : yabai -m window --display 3

      # new windows for most used apps
      ctrl + shift + alt - return   : /Users/rubikoid/dotfiles/mac_scripts/open_iterm.scpt # open -a iTerm /Users/rubikoid
      ctrl + shift + alt - k        : /Users/rubikoid/dotfiles/mac_scripts/open_safari.scpt 
    '';
  };

  security.pam.enableSudoTouchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
