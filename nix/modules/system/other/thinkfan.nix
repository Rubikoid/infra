{
  # think fan?
  services.thinkfan = {
    enable = true;
    
    levels = [
      [
        0
        0
        48
      ]
      [
        "level auto"
        45
        65
      ]
      [
        7
        63
        75
      ]
      [
        "level full-speed"
        70
        32767
      ]
    ];
  };
}
