{ inputs, pkgs, ... }:

{
  imports = [
    inputs.hyprland.homeManagerModules.default
  ];

  home.packages = (
    with pkgs; [
      inputs.anyrun.packages.${pkgs.system}.anyrun-with-all-plugins
      avizo # notify / light contol...
      swaylock-effects # i don't remember
    ]
  );

  # [
  #   
  # ] ++ (

  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    });

    settings = [{
      height = 34;
      spacing = 10;

      modules-left = [ "wlr/workspaces" ];
      modules-center = [ "hyprland/window" ];
      modules-right = [
        "tray"
        "network"
        "cpu"
        "memory"
        "temperature"
        "hyprland/language"
        "battery"
        "clock"
      ];

      "wlr/workspaces" = {
        on-click = "activate";
      };

      "hyprland/language" = {
        format = "{}";
        format-en = "🇺🇸";
        format-ru = "🇷🇺";
      };
    }];

    # ${builtins.readFile "${pkgs.waybar}/etc/xdg/waybar/style.css" }
    style = builtins.readFile ./graphics/waybar.css;
  };

  wayland.windowManager.hyprland = {
    # Enable hyprland
    enable = true;

    # enable xwayland, but without hidpi
    xwayland.enable = true;

    # patching wlroots for better Nvidia support (don't need on intel only)
    enableNvidiaPatches = false;

    # systemd, hyprland, nuff said
    systemdIntegration = true;

    extraConfig = builtins.readFile ./graphics/hyprland.conf;

    # plugins = [
    #   inputs.hyprland-plugins.packages.${pkgs.system}.hyprbars
    # ];
  };
}
