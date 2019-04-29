#!/bin/bash


diskfile=
kernel=


usage()
{
    cat << EOF
Usage:
$0 <options ...>

  Global:
    -h This help
    -k <kernel>
    -d <disk file>
    It can be run under deploy directory without parameters.
EOF
    exit 1
}


while getopts "k:d:h" arg
do
    case $arg in
    k)
        kernel=$OPTARG
        ;;
    d)
        diskfile=$OPTARG
        ;;
    h)
        usage
        ;;
    ?)
        echo "$0: invalid option -$OPTARG" 1>&2
        usage
        ;;
    esac
done

if [ -z $diskfile ];then
    diskfile=$(ls -lrt | grep .ext4$ | awk '{print $9}' | tail -n 1)
fi

if [ -z $kernel ];then
    kernel=$(ls -lrt | grep zImage | awk '{print $9}' | tail -n 1)
fi

if [ -z $kernel -o -z $diskfile ];then
    echo "Please set kernel and disk file"
    usage
fi


BOOTPARAMS="root=/dev/vda rw highres=off  mem=512M ip=192.168.7.2::192.168.7.1:255.255.255.0 console=ttyAMA0,38400"

#sudo qemu-system-arm -device virtio-net-device,netdev=net0,mac=52:54:00:12:34:02 -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
#-drive id=disk0,file=$diskfile,if=none,format=raw \
#-device virtio-blk-device,drive=disk0 -show-cursor -device virtio-rng-pci -monitor null -machine versatilepb -cpu cortex-a7 \
#-m 256  -s -nographic -serial mon:stdio -serial null -kernel $kernel -append '$BOOTPARAMS'

sudo qemu-system-arm -drive id=disk0,file=$diskfile,if=none,format=raw \
-device virtio-blk-device,drive=disk0 -show-cursor -device virtio-rng-pci -monitor null -machine versatilepb -cpu cortex-a7 \
-m 256  -s -nographic -serial mon:stdio -serial null -kernel $kernel -append '$BOOTPARAMS'
