{ ... }:
{
  services.smartd = {
    enable = true;

    devices = [ ];
    autodetect = true; # явно (but this is default)

    extraOptions = [ ];

    # auto detect type of disk
    # disable auto offline tests
    # defaults.monitored = "-d auto -o off";

    notifications = {
      wall.enable = true;
      test = true;
    };
  };
}
