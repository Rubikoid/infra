{ pkgs
, ...
}:
pkgs.stdenv.mkDerivation {
  name = "dhclient";
  version = "4.1.1";
  src = fetchTarball {
    url = "https://downloads.isc.org/isc/dhcp/4.4.3/dhcp-4.4.3.tar.gz";
    sha256 = "0ba23q4szjpilyqzw7h1n8almdib45rdl3wbpa3mgfg8xvf2nbkl";
  };
  buildInput = [
    pkgs.binutils
    pkgs.bintools-unwrapped
    pkgs.gnugrep
    pkgs.file
  ];
  configurePhase = ''
    #echo "checking configure"
    #./configure --disable-symtable --prefix $out
    ./configure --prefix $out
    cd client/scripts
    mv linux dhclient-script
    sed -i s,/bin/bash,${pkgs.bash}/bin/bash,g dhclient-script
    sed -i s,/sbin/ip,${pkgs.iproute2}/bin/ip,g dhclient-script
    sed -i s,mv,${pkgs.coreutils}/bin/mv,g dhclient-script
    sed -i s,rm,${pkgs.coreutils}/bin/rm,g dhclient-script
    sed -i s,chown,${pkgs.coreutils}/bin/chown,g dhclient-script
    sed -i s,chmod,${pkgs.coreutils}/bin/chmod,g dhclient-script
    sed -i s,seq,${pkgs.coreutils}/bin/seq,g dhclient-script
    sed -i s,sleep,${pkgs.coreutils}/bin/sleep,g dhclient-script
    sed -i s,grep,${pkgs.gnugrep}/bin/grep,g dhclient-script
    cd ../../includes
    sed -i s,/sbin/dhclient-script,$out/scripts/dhclient-script,g dhcpd.h
    cd ../
  '';
  buildPhase = ''
    cd bind
    tar -xvf bind.tar.gz
    cd bind-9.11.36
    ./configure --disable-symtable --without-python  --without-openssl --prefix $out
    cd ../..
    find -iname configure | xargs sed -i 's,/usr/bin/file,${pkgs.file}/bin/file,g'
    make -j 9
  '';
  installPhase = ''
    make install
    mkdir $out/scripts
    cp client/scripts/dhclient-script $out/scripts/
  '';
}
