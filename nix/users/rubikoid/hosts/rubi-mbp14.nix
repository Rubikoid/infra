{ inputs, pkgs, lib, ... }:
{
  imports =
    with lib.r.modules;
    (with user; [
      typical-env
      ghostty
      dotnet
    ])
    ++ (with darwin; [
      gc-debug
    ]);

  home.packages = with pkgs; [
    pkgs.nixpkgs-collection.nixpkgs-stable.ansible
    ffmpeg
    colima
    lima
    yt-dlp
    graphviz
    binwalk
    imagemagick
    qemu

    (copier.overridePythonAttrs (prev: {
      dependencies = prev.dependencies ++ (with pkgs.python3.pkgs; [
        cookiecutter
      ]);
    }))

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
