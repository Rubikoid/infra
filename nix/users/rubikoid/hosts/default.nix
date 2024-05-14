{ device, ... }:
{
  # import per-device config
  imports = [
    (./. + "/${device}.nix")
  ];
}
