{ inputs, pkgs, lib, ... }:
{
  imports = with lib.r.modules.user; [
    sops
    helix
    python
    dev
    shell
    atuin
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

    # ladybird
    # rustpython
    # (rustpython.withPackages (p: with p; [
    #   pydantic
    #   pydantic-settings
    # ])
    # )
  ];
}
