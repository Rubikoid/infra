{ inputs, pkgs, lib, ... }:
{
  imports =
    with lib.r.modules;
    (with user; [
      typical-env
      ghostty
    ])
    ++ (with darwin; [ 
      gc-debug
    ]);

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
