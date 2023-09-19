{
  description = "NixOS config for entire life...";

  inputs = {
    # nixos upstream
    # nixpkgs.url = "nixpkgs/nixos-22.11";
    nixpkgs.url = "nixpkgs/nixos-unstable";

    # home-manager upstream
    home-manager = {
      # url = github:nix-community/home-manager/release-22.11;
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # GUI things. WM, plugins
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins.url = "github:hyprwm/hyprland-plugins";
    # and launcher
    anyrun = {
      url = "github:Kirottu/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, hyprland, hyprland-plugins, anyrun }:
    let
      system = "x86_64-linux";
      overlays = [
        anyrun.overlay
        (self: super: (import ./overlays) {
          inherit (nixpkgs) lib;
          inherit self super;
        })
      ];
    in
    {
      homeConfigurations = (import ./outputs/home.nix {
        inherit inputs nixpkgs system home-manager;
        inherit overlays hyprland;
      });

      nixosConfigurations = (import ./outputs/system.nix {
        inherit (nixpkgs) lib;
        inherit inputs system;
        inherit overlays hyprland;
      });

      # devShell.${system} =
      #   (import ./outputs/installation.nix { inherit system nixpkgs; });
    };
}
