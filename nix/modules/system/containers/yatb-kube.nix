{ pkgs, ... }:
let
  minio = {
    secretKey = "asdasdasd";
    accessKey = "asdasdasd";
    consoleAddress = ":9101";
    listenAddress = ":9100";
  };
in
{
  containers.yatb-kube-master = {
    autoStart = false;

    # https://gist.github.com/zeratax/85f240b5547388ca4a45f70f8673bfbf
    enableTun = true;
    extraFlags = [ "--private-users-ownership=chown" ];
    additionalCapabilities = [
      ''all" --system-call-filter="add_key keyctl bpf" --capability="all''
    ];
    allowedDevices = [
      { node = "/dev/fuse"; modifier = "rwm"; }
      { node = "/dev/kmsg"; modifier = "rwm"; }
      { node = "/dev/mapper/control"; modifier = "rwm"; }
      { node = "/dev/consotruele"; modifier = "rwm"; }
    ];
    bindMounts = {
      kmsg = {
        hostPath = "/dev/kmsg";
        mountPoint = "/dev/kmsg";
        isReadOnly = false;
      };
      fuse = {
        hostPath = "/dev/fuse";
        mountPoint = "/dev/fuse";
        isReadOnly = false;
      };
    };

    config = { config, ... }: {
      nixpkgs.pkgs = pkgs;

      system.stateVersion = "24.05";
    };
  };

  # boot.kernel.sysctl = {
  #   # "vm.overcommit_memory" = "1";
  #   "kernel.panic" = "10";
  #   "kernel.panic_on_oops" = "1";
  # };
}
