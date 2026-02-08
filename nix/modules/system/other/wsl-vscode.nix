# stolen from https://github.com/K900/vscode-remote-workaround/blob/main/vscode.nix
# and https://nix-community.github.io/NixOS-WSL/how-to/vscode.html
{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.rubikoid.vscode-remote-workaround;
in
{
  imports = [
    inputs.vscode-server.nixosModules.default
  ];

  options.rubikoid.vscode-remote-workaround = {
    enable = lib.mkEnableOption "automatic VSCode remote server patch";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nodejs_24;
      defaultText = lib.literalExpression "pkgs.nodejs_24";
      description = lib.mdDoc "The Node.js package to use. You generally shouldn't need to override this.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.vscode-server = {
      enable = true;
      
    };
  };
}
