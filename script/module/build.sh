#!/bin/bash
KIMAGE=arch/arm/boot/zImage
PAGE_SIZE=4096
MASTER_DTB_NAME=masterDTB.4k
OUTPUT=../build
SRCDIR=../kernel
DTBTOOL=$PWD/dtbtool
MKBOOTIMG=$PWD/mkbootimg
#Avaaliable product are ar758x/ar759x
PRODUCT=ar758x    
#Avaaliable product are 1.7/2.2
VERSION=2.2    

usage()
{
    cat << EOF
Usage:
$0 <options ...>

  Global:
    -p <product>
    -v <yocto version>
  Available products: ar758x/ar759x/em91
  Available yocto version: 1.7/2.2/2.7
  Notes:
    Please copy defconfig and INITRAMFS files to the folder $0 run in"
EOF
    exit 1
}

gen_hash_pad() {
	mbnfile=$1
	hashfile=$2
	imagefile=$3
	pagesize=$4

	if [[ $pagesize -ne 2048 && $pagesize -ne 4096 ]];then
		echo "wrong page size:$pagesize"
		exit 1
	fi

	set `stat -c %s $mbnfile $hashfile`
	pad_len=`expr $pagesize - $1 - $2`
	dd if=/dev/zero bs=1 count=$pad_len of=pad.bin
	cat pad.bin >>$imagefile
	rm -f pad.bin
}


while getopts "p:v:" arg
do
    case $arg in
    p)
        PRODUCT=$OPTARG
        echo "Product: $PRODUCT"
        ;;
    v)
        VERSION=$OPTARG
        echo "VERSION: $VERSION"
        ;;
    ?)
        echo "$0: invalid option -$OPTARG" 1>&2
        usage
        ;;
    esac
done

case $VERSION in
    1.7)
        . /opt/swi/y17-ext/environment-setup-armv7a-vfp-neon-poky-linux-gnueabi
        ;;
    2.2)
        . /opt/swi/y22-ext/environment-setup-armv7a-neon-poky-linux-gnueabi
        ;;
    2.7)
        . /opt/swi/y27-ext/environment-setup-armv7ahf-neon-poky-linux-gnueabi
        ;;
    ?)
        echo "$0: invalid version -$VERSION" 1>&2
        usage
        ;;
esac

if [ "$PRODUCT" == "ar758x" ] && [ "$VERSION" == "1.7" ];then
    KERNEL_BASE=0x80000000
    TAG_OFFSET=0x88000000
    INITRAMFS=./mdm9x28-image-initramfs-swi-mdm9x28.cpio
    CMDLINE="console=ttyHSL0,115200 console=ttyHSL1,115200 root=/dev/ram rootfs_ro=true user1_fs=ubifs fudge_ro_rootfs=false verity=on debug_locks_verbose=1"
elif [ "$PRODUCT" == "ar758x" ] && [ "$VERSION" == "2.2" ];then
    KERNEL_BASE=0x80000000
    TAG_OFFSET=0x88000000
    INITRAMFS=./mdm9x28-image-initramfs-swi-mdm9x28-ar758x.cpio
    CMDLINE="console=ttyHSL0,115200 console=ttyHSL1,115200 root=/dev/ram rootfs_ro=true user1_fs=ubifs fudge_ro_rootfs=false verity=on "
elif [ "$PRODUCT" == "ar759x" ] && [ "$VERSION" == "1.7" ];then
    KERNEL_BASE=0x81800000
    TAG_OFFSET=0x82a00000
    INITRAMFS=./mdm9x40-image-initramfs-swi-mdm9x40.cpio
    CMDLINE="console=ttyHSL0,115200 console=ttyHSL1,115200 root=/dev/ram user1_fs=ubifs verity=on dynamic_debug.verbose=1 debug_locks_verbose=1"
elif [ "$PRODUCT" == "ar759x" ] && [ "$VERSION" == "2.2" ];then
    KERNEL_BASE=0x81800000
    TAG_OFFSET=0x82a00000
    INITRAMFS=./mdm9x40-image-initramfs-swi-mdm9x40-ar759x.cpio
    CMDLINE="console=ttyHSL0,115200 console=ttyHSL1,115200 root=/dev/ram user1_fs=ubifs verity=on fudge_ro_rootfs=false"
elif [ "$PRODUCT" == "em91" ] && [ "$VERSION" == "2.7" ];then
    KERNEL_BASE=0x80000000
    TAG_OFFSET=0x82000000
    INITRAMFS=./mdm-image-initramfs-swi-sdx55.cpio
    CMDLINE="root=/dev/ram rootfs_ro=true console=ttyMSM0,115200 verity=off androidboot.hardware=qcom msm_rtb.filter=0x237 androidboot.console=ttyMSM0 lpm_levels.sleep_disabled=1 firmware_class.path=/lib/firmware/updates service_locator.enable=1 net.ifnames=0"
    KIMAGE=arch/arm/boot/zImage-dtb
else
    echo "Wrong product or yocto version"
    usage
fi

if [ ! -f defconfig ] || [ ! -f $INITRAMFS ];then
    echo "Miss defconfig or $INITRAMFS"
    usage
fi

CMDLINE="$CMDLINE $IMA_PARAM $UBIFS_PARAM"
mkdir -p $OUTPUT
cp $INITRAMFS $OUTPUT
export LOCALVERSION=
export EXTRAVERSION=

[ ! -f $OUTPUT/.config ] && cp defconfig $OUTPUT/.config

#Fix version magic '3.18.31 preempt mod_unload ARMv7 p2v8 issue.
touch $SRCDIR/.scmversion
#ARCH=arm make -C $SRCDIR O=$OUTPUT oldconfig
ARCH=arm CROSS_COMPILE="ccache arm-poky-linux-gnueabi-" make -j8 -C $SRCDIR CC="ccache arm-poky-linux-gnueabi-gcc -mno-thumb-interwork -marm" \
    LD="arm-poky-linux-gnueabi-ld.bfd" O=$OUTPUT CONFIG_INITRAMFS_SOURCE=$INITRAMFS V=1
if [ $? -ne 0 ] ; then exit 1 ; fi

#build modules
ARCH=arm CROSS_COMPILE="ccache arm-poky-linux-gnueabi-" make -j8 -C $SRCDIR CC="ccache arm-poky-linux-gnueabi-gcc -mno-thumb-interwork -marm" \
    LD="arm-poky-linux-gnueabi-ld.bfd" O=$OUTPUT modules
if [ $? -ne 0 ] ; then exit 1 ; fi

cd $OUTPUT

if [ "$PRODUCT" != "em91" ];then
    [ -f ima-local-ca.x509 ] && cp ima-local-ca.x509 $OUTPUT
    # Make device tree
    $DTBTOOL arch/arm/boot/dts/qcom/ -s $PAGE_SIZE  -o $MASTER_DTB_NAME -p scripts/dtc/ -v
    if [ $? -ne 0 ] ; then exit 1 ; fi

    # Make boot image which could be fastbooted to the platform
    $MKBOOTIMG --dt $MASTER_DTB_NAME --kernel $KIMAGE --ramdisk /dev/null --cmdline "$CMDLINE" --pagesize $PAGE_SIZE \
        --base $KERNEL_BASE --tags-addr $TAG_OFFSET --ramdisk_offset 0x0 --output ./boot.img
    if [ $? -ne 0 ] ; then exit 1 ; fi
    # Append "mbn header" and "hash of kernel" to kernel image for data integrity check
    # "mbnhdr_data" is 40bytes mbn header data in hex string format
    mbnhdr_data="06000000030000000000000028000000200000002000000048000000000000004800000000000000"
    # Transfer data from hex string format to binary format "0x06,0x00,0x00,..." and write to a file.
    echo -n $mbnhdr_data | sed 's/\([0-9A-F]\{2\}\)/\\\\\\x\1/gI' | xargs printf > ./boot_mbnhdr
    openssl dgst -sha256 -binary ./boot.img > ./boot_hash
    cat ./boot_mbnhdr ./boot_hash >> ./boot.img
    gen_hash_pad boot_mbnhdr boot_hash boot.img 4096
else
    $MKBOOTIMG --kernel $KIMAGE --ramdisk /dev/null --cmdline "$CMDLINE" --board swi-sdx55 --base $KERNEL_BASE \
        --pagesize $PAGE_SIZE --tags-addr $TAG_OFFSET --ramdisk_offset 0x0 --output ./boot.img
fi
rm -f $SRCDIR/.scmversion
