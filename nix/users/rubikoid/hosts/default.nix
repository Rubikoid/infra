{ device, ... }:
{
  # magically import per-device config
  imports = [
    (./. + "/${device}.nix")
  ];
}
