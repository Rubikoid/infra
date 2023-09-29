{ pkgs, lib, config, ... }:

let
  toolPkgs = with pkgs; [
    ### Tools ###
    smartmontools # hdd, ssd smart
    pciutils # lspci
    usbutils # lsusb
    nix-index # nix-lookup for binary
    ldns # dns help
    tcpdump # oh yes sniff everything
  ];

  pythonPackages = ps: with ps; [
    pip
    fastapi
  ];

  devPkgs = with pkgs; [
    ### Development ###
    # code
    (python311.withPackages pythonPackages) # python...
    step-cli # certificate management
    cargo
    rustc
    rust-analyzer
    gnumake
    go
    protobuf
    protoc-gen-go
  ];

  graphicsPkgs = with pkgs; [
    keepassxc # keepass...
    firefox # browser
    tdesktop # telegram...
    obsidian # obsidian!
    rnote # note taking thing
    keepass
    keepass-keeagent
  ];

  otherPkgs = with pkgs; [
    lm_sensors # sensors....
    syncthing # more synchronization for the sync god
    helix # strange editor
  ];
in
{
  imports = with inputs.self.homeProfiles; [
    alacritty
    graphics
  ];

  programs = {
    home-manager.enable = true;
  };

  home.packages = toolPkgs ++ devPkgs ++ graphicsPkgs ++ otherPkgs;

  services = {
    gpg-agent = {
      enable = true;
      enableSshSupport = false;
      #enableExtraSocket = true;
      # pinentryFlavor = "curses";
      # defaultCacheTtl = 34560000;
      # defaultCacheTtlSsh = 34560000;
      # maxCacheTtl = 34560000;
      # maxCacheTtlSsh = 34560000;
      # extraConfig = "display :0";
    };

    syncthing = {
      enable = true;
      extraOptions = [ ];
    };
  };


}
