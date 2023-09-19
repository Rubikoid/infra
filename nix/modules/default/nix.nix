{
  nix = {
    # idk wtf is it, but sounds good;
    optimise.automatic = true;

    # nix command, flakes
    settings.experimental-features = [ "nix-command" "flakes" ];
  };
}
