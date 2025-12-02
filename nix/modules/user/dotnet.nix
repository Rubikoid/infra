{ pkgs, secrets, ... }:
{
  home.packages =
    with pkgs;
    [
      dotnet-sdk
      dotnet-aspnetcore
      dotnet-runtime
      dotnetPackages.Nuget 
    ];
}
