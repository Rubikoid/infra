{
  # tmp
  networking.firewall = {
    allowedTCPPorts = [ 111 2049 4000 4001 4002 20048 ];
    allowedUDPPorts = [ 111 2049 4000 4001 4002 20048 ];
  };

  services.nfs.server = {
    enable = true;

    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
    extraNfsdConfig = '''';

    # exports = ''
    #   /mnt         192.168.1.100(ro,insecure,nohide,no_subtree_check)
    # '';
  };
}
