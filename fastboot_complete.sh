#!/bin/bash

usage()
{
    cat << EOF
Usage:
$0 <options ...>

  Global:
    -w <workspace dir>
    -p  pcie image
EOF
    exit 1
}

pcie_flag=0

while getopts "w:p" arg
do
    case $arg in
    w)
        WORKSPACE=$OPTARG
        echo "WORKSPACE: $WORKSPACE"
        [ -z $WORKSPACE ] && usage
        [ ! -d $WORKSPACE ] && usage
        [ ! -d $WORKSPACE/build_src ] && usage
        ;;
    p)
        pcie_flag=1
        ;;
    ?)
        echo "$0: invalid option -$OPTARG" 1>&2
        usage
        ;;
    esac
done


echo "fastboot erase abl && fastboot flash abl $WORKSPACE/build_src/tmp/deploy/images/swi-sdx55/abl.elf"
fastboot erase abl && fastboot flash abl $WORKSPACE/build_src/tmp/deploy/images/swi-sdx55/abl.elf
[ $? -ne 0 ] && exit 1

echo "fastboot erase aop && fastboot flash aop $WORKSPACE/sdx55/SDX55_aop/aop_proc/build/ms/bin/AAAAANAZO/aop.mbn"
fastboot erase aop && fastboot flash aop $WORKSPACE/sdx55/SDX55_aop/aop_proc/build/ms/bin/AAAAANAZO/aop.mbn
[ $? -ne 0 ] && exit 1

echo "fastboot erase boot && fastboot flash boot $WORKSPACE/build_src/tmp/deploy/images/swi-sdx55/boot-yocto-sdx55.img"
fastboot erase boot && fastboot flash boot $WORKSPACE/build_src/tmp/deploy/images/swi-sdx55/boot-yocto-sdx55.img
[ $? -ne 0 ] && exit 1

echo "fastboot erase modem && fastboot flash modem $WORKSPACE/sdx55/common/build/nand/NON-HLOS.ubi"
fastboot erase modem && fastboot flash modem $WORKSPACE/sdx55/common/build/nand/NON-HLOS.ubi
[ $? -ne 0 ] && exit 1

echo "fastboot erase multi_image && fastboot flash multi_image $WORKSPACE/sdx55/common/build/nand/multi_image.mbn"
fastboot erase multi_image && fastboot flash multi_image $WORKSPACE/sdx55/common/build/nand/multi_image.mbn
[ $? -ne 0 ] && exit 1

echo "fastboot erase qhee && fastboot flash qhee $WORKSPACE/sdx55/SDX55_tz/trustzone_images/build/ms/bin/EATAANBA/hyp.mbn"
fastboot erase qhee && fastboot flash qhee $WORKSPACE/sdx55/SDX55_tz/trustzone_images/build/ms/bin/EATAANBA/hyp.mbn
[ $? -ne 0 ] && exit 1

if [ $pcie_flag -eq 1 ];then
    img=$WORKSPACE/sdx55/SDX55_boot/boot_images/build/ms/bin/sdx55/nand_pcie/sbl1.mbn
else
    img=$WORKSPACE/sdx55/SDX55_boot/boot_images/build/ms/bin/sdx55/nand/sbl1.mbn
fi
echo "fastboot erase sbl && fastboot flash sbl $img"
fastboot erase sbl && fastboot flash sbl $img
[ $? -ne 0 ] && exit 1

echo "fastboot erase sec && fastboot flash sec $WORKSPACE/sdx55/common/config/sec/sec.elf"
fastboot erase sec && fastboot flash sec $WORKSPACE/sdx55/common/config/sec/sec.elf
[ $? -ne 0 ] && exit 1

echo "fastboot erase system && fastboot flash system $WORKSPACE/build_src/tmp/deploy/images/swi-sdx55/mdm-image-minimal-swi-sdx55.ubi"
fastboot erase system && fastboot flash system $WORKSPACE/build_src/tmp/deploy/images/swi-sdx55/mdm-image-minimal-swi-sdx55.ubi
[ $? -ne 0 ] && exit 1

echo "fastboot erase tz && fastboot flash tz $WORKSPACE/sdx55/SDX55_tz/trustzone_images/build/ms/bin/EATAANBA/tz.mbn"
fastboot erase tz && fastboot flash tz $WORKSPACE/sdx55/SDX55_tz/trustzone_images/build/ms/bin/EATAANBA/tz.mbn
[ $? -ne 0 ] && exit 1

echo "fastboot erase tz_devcfg && fastboot flash tz_devcfg $WORKSPACE/sdx55/SDX55_tz/trustzone_images/build/ms/bin/EATAANBA/devcfg.mbn"
fastboot erase tz_devcfg && fastboot flash tz_devcfg $WORKSPACE/sdx55/SDX55_tz/trustzone_images/build/ms/bin/EATAANBA/devcfg.mbn
[ $? -ne 0 ] && exit 1

echo "fastboot erase uefi && fastboot flash uefi $WORKSPACE/sdx55/SDX55_uefi/boot_images/QcomPkg/SDX55Pkg/Bin/SDX55/LE/RELEASE/uefi.elf"
fastboot erase uefi && fastboot flash uefi $WORKSPACE/sdx55/SDX55_uefi/boot_images/QcomPkg/SDX55Pkg/Bin/SDX55/LE/RELEASE/uefi.elf
[ $? -ne 0 ] && exit 1

echo "fastboot erase  xbl_config && fastboot flash  xbl_config $WORKSPACE/sdx55/SDX55_boot/boot_images/build/ms/bin/sdx55/xbl_cfg.elf"
fastboot erase  xbl_config && fastboot flash  xbl_config $WORKSPACE/sdx55/SDX55_boot/boot_images/build/ms/bin/sdx55/xbl_cfg.elf
[ $? -ne 0 ] && exit 1

