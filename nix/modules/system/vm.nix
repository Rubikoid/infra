# https://github.com/name-snrl/nixos-configuration/blob/master/modules/nixos/profiles/system/vm-config.nix
{
  virtualisation.vmVariant =
    { pkgs, ... }:
    {
      services.getty.autologinUser = "root";
      virtualisation = {
        cores = 2;
        memorySize = 2 * 1024;
        diskImage = null;
        # https://wiki.qemu.org/Documentation/9psetup#Performance_Considerations_(msize)
        # I set it to 1MB, but in tests there was no difference compared to the default value (16KB)
        msize = 1024 * 1024;
        sharedDirectories.experiments = {
          source = "$HOME";
          target = "/mnt/shared";
        };

        forwardPorts = [ ];

        # To search for options:
        # qemu-kvm -device 'virtio-vga-gl,?'
        # qemu-kvm -device help
        qemu.options = [
          # "-net nic,model=rtl8139"
          # "-net user,hostfwd=tcp::9900-:9900"
          # "-cpu host"
          # "-enable-kvm"
          # "-vga none"

          # "-device virtio-gpu-gl,edid=on,xres=1920,yres=1080"
          # "-audio pipewire,model=hda"

          # qemu GTK
          #"-display gtk,gl=on,full-screen=on,grab-on-hover=on,zoom-to-fit=off"

          # spice
          # "-display spice-app,gl=on"
          # "-spice gl=on"
          # "-device virtio-serial-pci"
          # "-device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0"
          # "-chardev spicevmc,id=spicechannel0,name=vdagent"
        ];
      };
    };
}
