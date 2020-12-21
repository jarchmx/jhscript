#! /bin/sh

reqid=0
cfg_localnic()
{
    dev=$1
    ip=$2
    peerip=$3
    peermac=$4
    inspi=$5
    outspi=$6
    #ireqid=`expr $reqid + 1`
    ireqid=`expr $reqid + 0`
    ifconfig $dev down
    ifconfig $dev $ip/24 up
    ip neigh flush dev $dev
    arp -i $dev -s $peerip $peermac
    ip neigh show dev $dev
    iptables --flush
    ip xfrm policy add src $ip dst $peerip dir out ptype main action allow tmpl src $ip dst $peerip proto esp mode transport reqid $reqid
    ip xfrm policy add src $peerip dst $ip dir in ptype main action allow tmpl src $peerip dst $ip proto esp mode transport reqid $ireqid
    ip xfrm state add src $ip dst $peerip proto esp spi $outspi reqid $reqid mode transport replay-window 64 auth sha1 0x4339314b55523947594d6d3547666b45764e6a58 enc aes 0x4a506a794f574265564551694d653768
    ip xfrm state add src $peerip dst $ip proto esp spi $inspi reqid $ireqid mode transport replay-window 64 auth sha1 0x4339314b55523947594d6d3547666b45764e6a58 enc aes 0x4a506a794f574265564551694d653768
}

ip xfrm policy flush
ip xfrm state flush

cfg_localnic eth1 192.168.1.1 192.168.1.2 00:04:9f:04:ae:7d 1001 1000
    
ip xfrm policy list
ip xfrm state list
