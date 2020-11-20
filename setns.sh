#!/bin/sh


usage()
{
	echo "Usage:"
	echo "	$0 <netns_id> <ip_addr>"
	exit 0
}


[ -z $1 ] && usage
[ -z $2 ] && usage


netnsid=$1
ipaddr=$2

prefix=`echo $ipaddr | awk -F'.' '{printf("%s.%s.%s",$1,$2,$3)}'`

net="$prefix".0/24

peer="$prefix".2/24


ip netns add clt_$netnsid

ip link add veth$netnsid type veth peer name veth1


ip addr add $ipaddr/24 dev veth$netnsid
ip link set dev veth$netnsid up
#ip route add $net dev veth$netnsid


ip link set dev veth1 netns clt
ip netns exec clt ip link set dev veth1 name eth0
ip netns exec clt ip addr add $peer dev eth0
ip netns exec clt ip link set dev eth0 up
ip netns exec clt ip route add default dev eth0 via $ipaddr

#iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#iptables -t nat -A POSTROUTING -s $net -o eth0 -j MASQUERADE

#iptables -A FORWARD -s $net -j ACCEPT
