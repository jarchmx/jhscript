#!/bin/bash


diskfile=
kernel=
dtb=

usage()
{
    cat << EOF
Usage:
$0 <options ...>

  Global:
    -h This help
    -k <kernel>
    -d <disk file>
    -b <dtb file>
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
    d)
        dtb=$OPTARG
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
    file=$(ls -lrt | grep .ext4$ | awk '{print $9}' | tail -n 1)
    diskfile=$PWD/$file
fi

if [ -z $kernel ];then
    file=$(ls -lrt $PWD | grep zImage | awk '{print $9}' | tail -n 1)
    kernel=$PWD/$file
fi

if [ -z $dtb ];then
    file=$(ls -lrt $PWD | grep .dtb$ | awk '{print $9}' | tail -n 1)
    dtb=$PWD/$file
fi

if [ -z $kernel -o -z $diskfile ];then
    echo "Please set kernel and disk file"
    usage
fi


#BOOTPARAMS="root=/dev/vda rw highres=off  mem=256M ip=192.168.7.2::192.168.7.1:255.255.255.0 console=ttyAMA0,115200 console=tty"

if [ -z $dtb ];then
 qemu-system-arm -device virtio-net-pci,netdev=net0,mac=52:54:00:12:34:02 -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
-drive file=$diskfile,if=virtio,format=raw -show-cursor -usb -device usb-tablet -device virtio-rng-pci  -machine versatilepb  -m 256  \
-nographic -serial mon:stdio -serial null -kernel $kernel -s 
-append 'root=/dev/vda rw highres=off  mem=256M ip=192.168.7.2::192.168.7.1:255.255.255.0 console=ttyAMA0,115200 console=tty ' 
else
qemu-system-arm -device virtio-net-pci,netdev=net0,mac=52:54:00:12:34:02 -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
-drive file=$diskfile,if=virtio,format=raw -show-cursor -usb -device usb-tablet -device virtio-rng-pci  -machine versatilepb  -m 256  \
-nographic -serial mon:stdio -serial null -kernel $kernel -dtb $dtb -s \
-append 'root=/dev/vda rw highres=off  mem=256M ip=192.168.7.2::192.168.7.1:255.255.255.0 console=ttyAMA0,115200 console=tty ' 
fi
