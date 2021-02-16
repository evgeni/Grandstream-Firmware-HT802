sudo apt-get install build-essential gcc-arm-linux-gnueabi ca-certificates

mkdir /tmp/ovpnsta/

# LZO
cd /tmp/ovpnsta/
wget https://www.oberhumer.com/opensource/lzo/download/lzo-2.10.tar.gz
tar xvzf lzo-2.10.tar.gz && cd lzo-2.10
./configure --prefix=/tmp/ovpnsta/vpn_compile --enable-static --target=arm-linux-gnueabi --host=arm-linux-gnueabi
make && make install

# LZ4
cd /tmp/ovpnsta/
wget https://github.com/lz4/lz4/archive/v1.9.2.tar.gz
tar xvzf v1.9.2.tar.gz && cd lz4-1.9.2
make && PREFIX=/tmp/ovpnsta/vpn_compile make install

# OpenSSL
cd /tmp/ovpnsta/
wget https://www.openssl.org/source/openssl-1.1.1h.tar.gz
tar xvzf openssl-1.1.1h.tar.gz && cd openssl-1.1.1h
./Configure gcc -static -no-shared --prefix=/tmp/ovpnsta/vpn_compile --cross-compile-prefix=arm-linux-gnueabi-
make && make install

# OpenVPN
cd /tmp/ovpnsta/
wget https://swupdate.openvpn.org/community/releases/openvpn-2.4.9.tar.gz
tar xvzf openvpn-2.4.9.tar.gz && cd openvpn-2.4.9
./configure --target=arm-linux-gnueabi --host=arm-linux-gnueabi --prefix=/tmp/ovpnsta/vpn_compile --enable-static --disable-shared --disable-debug --disable-plugins OPENSSL_CFLAGS="-I/tmp/ovpnsta/vpn_compile/include" OPENSSL_LIBS="-L/tmp/ovpnsta/vpn_compile/lib -lssl -lcrypto" LZO_CFLAGS="-I/tmp/ovpnsta/vpn_compile/include" LZO_LIBS="-L/tmp/ovpnsta/vpn_compile/lib -llzo2" LZ4_CFLAGS="-I/tmp/ovpnsta/vpn_compile/include" LZ4_LIBS="-L/tmp/ovpnsta/vpn_compile/lib -llz4" IFCONFIG=/sbin/ifconfig ROUTE=/sbin/route NETSTAT=/bin/netstat IPROUTE=/sbin/ip --enable-iproute2
make LIBS="-all-static" && make install

# Strip
cd /tmp/ovpnsta/
cp /tmp/ovpnsta/vpn_compile/sbin/openvpn .
strip -s openvpn
file openvpn
ls -la openvpn
