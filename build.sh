#!/bin/bash
#IMA_PARAM="ima_tcb ima_appraise=fix ima_appraise_tcb"
#UBIFS_PARAM="fudge_ro_rootfs=true"
CMDLINE="console=ttyHSL0,115200 console=ttyHSL1,115200 root=/dev/ram rootfs_ro=true user1_fs=ubifs fudge_ro_rootfs=false verity=on debug_locks_verbose=1"
#CMDLINE="console=ttyHSL0,115200 console=ttyHSL1,115200 root=/dev/ram rootfs_ro=true user1_fs=ubifs fudge_ro_rootfs=false verity=on ima_appraise=enforce ima_appraise_tcb"
CMDLINE="$CMDLINE $IMA_PARAM $UBIFS_PARAM"
KNAME=zImage
KIMAGE=arch/arm/boot/zImage
KERNEL_BASE=0x80000000
TAG_OFFSET=0x88000000
PAGE_SIZE=4096
MASTER_DTB_NAME=masterDTB.4k
OUTPUT=../build
INITRAMFS=./mdm9x28-image-initramfs-swi-mdm9x28.cpio
SRCDIR=../kernel
DTBTOOL=$PWD/dtbtool
MKBOOTIMG=$PWD/mkbootimg
# source profile
# ARCH=arm make mrproper
# ARCH=arm make distclean
# ARCH=arm make mdm9607_defconfig
# Create kernel image bundled with initramfs
mkdir -p $OUTPUT
. /opt/swi/y17-ext/environment-setup-armv7a-vfp-neon-poky-linux-gnueabi

cp $INITRAMFS $OUTPUT
#export LOCALVERSION=
[ -f ima-local-ca.x509 ] && cp ima-local-ca.x509 $OUTPUT
[ ! -f $OUTPUT/.config ] && cp defconfig $OUTPUT/.config
#cp ima_config $OUTPUT/.config
#ARCH=arm make -C $SRCDIR O=$OUTPUT oldconfig
ARCH=arm CROSS_COMPILE="ccache arm-poky-linux-gnueabi-" make -j8 -C $SRCDIR CC="ccache arm-poky-linux-gnueabi-gcc -mno-thumb-interwork -marm" \
	LD="arm-poky-linux-gnueabi-ld.bfd" O=$OUTPUT CONFIG_INITRAMFS_SOURCE=$INITRAMFS V=1
if [ $? -ne 0 ] ; then exit 1 ; fi
#if [ $? -ne 0 ] ; then exit 1 ; fi
#cp ./dtbtool $OUTPUT
#cp ./mkbootimg $OUTPUT

cd $OUTPUT
cp $KIMAGE .
if [ $? -ne 0 ] ; then exit 1 ; fi

# Make device tree
$DTBTOOL arch/arm/boot/dts/qcom/ -s $PAGE_SIZE  -o $MASTER_DTB_NAME -p scripts/dtc/ -v
if [ $? -ne 0 ] ; then exit 1 ; fi

# Make boot image which could be fastbooted to the platform
$MKBOOTIMG --dt $MASTER_DTB_NAME --kernel $KNAME --ramdisk /dev/null --cmdline "$CMDLINE" --pagesize $PAGE_SIZE \
	--base $KERNEL_BASE --tags-addr $TAG_OFFSET --ramdisk_offset 0x0 --output ./boot.img
if [ $? -ne 0 ] ; then exit 1 ; fi
# Append "mbn header" and "hash of kernel" to kernel image for data integrity check
# "mbnhdr_data" is 40bytes mbn header data in hex string format
mbnhdr_data="06000000030000000000000028000000200000002000000048000000000000004800000000000000"
# Transfer data from hex string format to binary format "0x06,0x00,0x00,..." and write to a file.
echo -n $mbnhdr_data | sed 's/\([0-9A-F]\{2\}\)/\\\\\\x\1/gI' | xargs printf > ./boot_mbnhdr
openssl dgst -sha256 -binary ./boot.img > ./boot_hash
cat ./boot_mbnhdr ./boot_hash >> ./boot.img
set `stat -c %s boot_hash boot_mbnhdr`
pad_len=`expr 4096 - $1 - $2`
dd if=/dev/zero bs=1 count=$pad_len of=pad.bin
cat ./pad.bin >>./boot.img
