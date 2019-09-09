#!/bin/sh

#[ -z $1 ] && echo "please run $0 mhinet.ko" && exit 1
#[ ! -f $1 ] && echo "$1 not exist" && exit 1
#MHIDRIVER=$1

#insmod $MHIDRIVER
#sleep 5

#mbimcli -d /dev/mhichar0 -v -p --set-radio-state=off
#[ $? -ne 0 ] && exit 1
#sudo mbimcli -d /dev/mhichar0 -p --query-radio-state --no-close  -v
echo mbimcli -d /dev/mhichar0 -v -p --set-radio-state=on
mbimcli -d /dev/mhichar0 -v -p --set-radio-state=on
[ $? -ne 0 ] && exit 1
#export PROXY=yes
echo mbim-network /dev/mhichar0 start
mbim-network /dev/mhichar0 start
[ $? -ne 0 ] && exit 1
#mbimcli -d /dev/mhichar0 -v -p --query-ip-configuration
#[ $? -ne 0 ] && exit 1

rm -f /tmp/ip.txt
echo mbimcli -d /dev/mhichar0 -v -p --query-ip-configuration
mbimcli -d /dev/mhichar0 -v -p --query-ip-configuration 2>&1 | tee /tmp/ip.txt
[ $? -ne 0 ] && exit 1

echo "Configure the network"
ip route del default 
IP=`cat /tmp/ip.txt | grep 'IP \[0\]' | head -n 1 | awk -F\' '{print $2}'`
MTU=`cat /tmp/ip.txt  | grep MTU: | head -n 1 | awk -F\' '{print $2}'`
GW=`cat /tmp/ip.txt  | grep Gateway: | head -n 1 | awk -F\' '{print $2}'`
DNS1=`cat /tmp/ip.txt  | grep "DNS \[0\]" | head -n 1 | awk -F\' '{print $2}'`
DNS2=`cat /tmp/ip.txt  | grep "DNS \[1\]" | head -n 1 | awk -F\' '{print $2}'`
MTU=`expr $MTU + 14`
echo "IP:$IP, MTU:$MTU DNS1:$DNS1 Gateway:$GW DNS2:DNS2"
ip addr flush dev wwan0
ip addr add $IP dev wwan0
ip link set wwan0 up
ip route add default via $GW dev wwan0

echo "Update DNS"
cp /etc/resolv.conf /etc/resolv.conf.bak
[ -n $DNS1 ] && echo "nameserver $DNS1" >/etc/resolv.conf
[ -n $DNS2 ] && echo "nameserver $DNS2" >>/etc/resolv.conf

