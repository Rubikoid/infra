{ pkgs, config, secrets, inputs, lib, utils, ... }:

{
  imports = with inputs.self.systemModules; [
    hm
    locale
    zsh
    zsh-config

    # ca
    ca_rubikoid

    # users
    rubikoid

    # containers

    remote-build
  ];

  environment.systemPackages = with pkgs; [

  ] ++ [
    (pkgs.writeShellScriptBin
      "vscode-server-env-setup.sh"
      (builtins.readFile (./. + "/vscode-server-env-setup.sh"))
    )
  ];

  programs = {
    direnv.enable = true;
  };

  wsl = {
    enable = true;
    defaultUser = "rubikoid";
    nativeSystemd = true;
    useWindowsDriver = true;

    wslConf = {
      network.generateResolvConf = false;
    };
  };

  # programs.nix-ld.enable = true;

  hardware.graphics.enable = lib.mkForce false;
  hardware.opengl.enable = lib.mkForce false;

  networking.nameservers = [
    "192.168.1.107"
  ];

  # virtualisation.podman.enable = true;
  # users.users.rubikoid.extraGroups = [ "docker" ];

  services.ferretdb = {
    enable = true;
    settings = {
      FERRETDB_LISTEN_ADDR = ":27017";
      FERRETDB_TELEMETRY = "disabled";
    };
  };

  system.activationScripts.gitbash =
    let
      srcShell = config.users.users.rubikoid.shell;
      shell =
        let
          shellPath = utils.toShellPath srcShell;
          wrapper = pkgs.stdenvNoCC.mkDerivation {
            name = "wrapped-${lib.last (lib.splitString "/" (shellPath))}";
            buildCommand = ''
              mkdir -p $out
              cp ${config.system.build.nativeUtils}/bin/shell-wrapper $out/wrapper
              ln -s ${shellPath} $out/shell
            '';
          };
        in
        wrapper.outPath + "/wrapper";
    in
    lib.stringAfter [ "setupLogin" ] ''
      echo "setting up /bin/bash (fake ;) )..."
      ln -sf ${shell} /bin/bash
    '';
  #  ln -sf ${pkgs.git}/bin/git /bin/git

  system.stateVersion = "24.05"; # Did you read the comment?
}
