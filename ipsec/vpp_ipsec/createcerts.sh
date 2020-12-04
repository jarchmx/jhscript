#!/bin/sh
#!/bin/bash

INSTALLDIR="/usr/local"
CONFIGPATH="$INSTALLDIR/etc"
SERVER_HOST=moon.askey.com
SERVER_IP=192.168.1.1
CLIENT_HOST=sun.askey.com
CLIENT_IP=192.168.1.2

# remove old files
rm -rf cert > /dev/null 2>&1
mkdir cert && cd cert

# create CA certificate
echo -e "\033[32mCreate CA certificate...\033[0m"
pki --gen --outform pem > ca.key.pem
pki --self --in ca.key.pem --dn "C=CN, O=Askey, CN=Askey CA" --ca --outform pem > ca.cert.pem

# create server certificate
echo -e "\033[32mCreate server certificate...\033[0m"
pki --gen --outform pem > moon.key.pem
pki --pub --in moon.key.pem | ipsec pki --issue --cacert ca.cert.pem \
  --cakey ca.key.pem --dn "C=CN, O=Askey, CN=$SERVER_HOST" \
  --san "$SERVER_HOST" --san="$SERVER_IP" --flag serverAuth --flag ikeIntermediate \
  --outform pem > moon.cert.pem

# create client certificate
echo -e "\033[32mCreate client certificate...\033[0m"
pki --gen --outform pem > sun.key.pem
pki --pub --in sun.key.pem | ipsec pki --issue --cacert ca.cert.pem \
	--cakey ca.key.pem --dn "C=CN, O=StrongSwan, CN=$CLIENT_HOST" \
	--san "$CLIENT_HOST" --san="CLIENT_IP" \
	--outform pem > sun.cert.pem


#echo -e "\033[32mInstall certificate...\033[0m"
#cp ca.cert.pem $CONFIGPATH/swanctl/x509ca/ 
#cp moon.cert.pem $CONFIGPATH/swanctl/x509/
#cp moon.key.pem $CONFIGPATH/swanctl/private/
#cp moon.conf $CONFIGPATH/swanctl/conf.d/ 
#sshpass -pnsfocus scp ca.cert.pem $sun:$CONFIGPATH/swanctl/x509ca/
#sshpass -pnsfocus scp sun.cert.pem $sun:$CONFIGPATH/swanctl/x509/
#sshpass -pnsfocus scp sun.key.pem $sun:$CONFIGPATH/swanctl/private/
#sshpass -pnsfocus scp sun.conf $CONFIGPATH/swanctl/conf.d/ 


#echo "load creds and connections"
#sudo swanctl -s
#sudo swanctl -c
