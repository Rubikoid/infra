{ inputs, ... }:
{
  imports = [
    inputs.microvm.nixosModules.microvm
  ];
}
