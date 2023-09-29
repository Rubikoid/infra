{ pkgs, ... }:

{
  # think fan?
  environment.systemPackages = with pkgs; [
    thinkfan
  ];

  services.thinkfan = {
    enable = true;
  };
}
