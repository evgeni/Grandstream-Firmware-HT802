sudo apt-get install gcc-arm-linux-gnueabi

mkdir /tmp/ovpnsta/

# OpenSSL
cd /tmp/ovpnsta/
wget https://www.openssl.org/source/openssl-1.0.2j.tar.gz
tar -xvf openssl-1.0.2j.tar.gz && cd openssl-1.0.2j
./Configure gcc -static -no-shared --prefix=/tmp/ovpnsta/vpn_compile --cross-compile-prefix=arm-linux-gnueabi-
make
make install

# LZO
cd /tmp/ovpnsta/
wget http://www.oberhumer.com/opensource/lzo/download/lzo-2.09.tar.gz
tar -xvf lzo-2.09.tar.gz && cd lzo-2.09
./configure --prefix=/tmp/ovpnsta/vpn_compile --enable-static --target=arm-linux-gnueabi --host=arm-linux-gnueabi --disable-debug
make
make install

# OpenVPN
cd /tmp/ovpnsta/
wget https://swupdate.openvpn.org/community/releases/openvpn-2.3.12.tar.gz
tar -xvf openvpn-2.3.12.tar.gz && cd openvpn-2.3.12
./configure --target=arm-linux-gnueabi --host=arm-linux-gnueabi --prefix=/tmp/ovpnsta/vpn_compile --disable-server --enable-static --disable-shared --disable-debug --disable-plugins OPENSSL_SSL_LIBS="-L/tmp/ovpnsta/vpn_compile/lib -lssl" OPENSSL_SSL_CFLAGS="-I/tmp/ovpnsta/vpn_compile/include" OPENSSL_CRYPTO_LIBS="-L/tmp/ovpnsta/vpn_compile/lib -lcrypto" OPENSSL_CRYPTO_CFLAGS="-I/tmp/ovpnsta/vpn_compile/include" LZO_CFLAGS="-I/tmp/ovpnsta/vpn_compile/include" LZO_LIBS="-L/tmp/ovpnsta/vpn_compile/lib -llzo2"
make LIBS="-all-static"
make install

# Strip
cd /tmp/ovpnsta/
cp /tmp/ovpnsta/vpn_compile/sbin/openvpn .
strip -s openvpn
file openvpn
ls -la openvpn
