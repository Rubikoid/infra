{ inputs, pkgs, ... }:
{
  imports = with inputs.self.userModules; [
    sops
    helix
    python
  ];

  home.packages = with pkgs; [
    ansible
    ffmpeg
    colima
    lima
    yt-dlp
    graphviz
    binwalk
    imagemagick
    qemu

    # glib, gobject-introspection, harfbuzz, ldc, librsvg, lima, llvm, python-tk@3.12, qt@5 and yt-dlp
    # 
    nil
    nixpkgs-fmt
  ];
}

