#! /bin/sh

export REMOTE_HOST=10.8.18.182


cfg_tap()
{
    dev=$1
    ip=$2
    gw=$3
    gw_mac=$4

    ifconfig $dev $ip/24 up
    ip neigh flush dev $dev
    ip neigh add $gw dev $dev lladdr $gw_mac
    ip neigh show dev $dev
    ifconfig $dev mtu 1400
}

reqid=1
cfg_remote()
{
    dev=$1
    ip=$2
    peerip=$3
    peermac=$4
    spi=$5
    ireqid=`expr $reqid + 1`
    ssh $REMOTE_HOST ifconfig $dev down
    ssh $REMOTE_HOST ifconfig $dev $ip/24 up
    ssh $REMOTE_HOST ip neigh flush dev $dev
    ssh $REMOTE_HOST arp -i $dev -s $peerip $peermac
    ssh $REMOTE_HOST ip neigh show dev $dev
    ssh $REMOTE_HOST iptables --flush
    ssh $REMOTE_HOST ip xfrm policy add src $ip dst $peerip dir out ptype main action allow tmpl src $ip dst $peerip proto esp mode tunnel reqid $reqid
    ssh $REMOTE_HOST ip xfrm policy add src $peerip dst $ip dir in ptype main action allow tmpl src $peerip dst $ip proto esp mode tunnel reqid $ireqid
    ssh $REMOTE_HOST ip xfrm state add src $ip dst $peerip proto esp spi $spi reqid $reqid mode tunnel replay-window 64 auth sha1 0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef enc aes 0xdeadbeefdeadbeefdeadbeefdeadbeef
    ssh $REMOTE_HOST ip xfrm state add src $peerip dst $ip proto esp spi $spi reqid $ireqid mode tunnel replay-window 64 auth sha1 0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef enc aes 0xdeadbeefdeadbeefdeadbeefdeadbeef
    reqid=`expr $reqid + 2`
}

cfg_tap dtap0 192.168.1.2 192.168.1.1 6c:b3:11:11:71:5c
cfg_tap dtap1 192.168.2.2 192.168.2.1 6c:b3:11:11:71:5d
cfg_tap dtap2 192.168.3.2 192.168.3.1 6c:b3:11:11:71:5e
cfg_tap dtap3 192.168.4.2 192.168.4.1 6c:b3:11:11:71:5f


ssh $REMOTE_HOST ip xfrm policy flush
ssh $REMOTE_HOST ip xfrm state flush

cfg_remote eth1 192.168.1.1 192.168.1.2 00:64:74:61:70:30 1
cfg_remote eth2 192.168.2.1 192.168.2.2 00:64:74:61:70:31 2
cfg_remote eth3 192.168.3.1 192.168.3.2 00:64:74:61:70:32 3
cfg_remote eth4 192.168.4.1 192.168.4.2 00:64:74:61:70:33 4
    
ssh $REMOTE_HOST ip xfrm policy list
ssh $REMOTE_HOST ip xfrm state list
