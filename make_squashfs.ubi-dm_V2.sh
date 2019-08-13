#!/bin/sh
#2017-07-27 V2 Caupar Gu
# TOOL_PATH="/home/user/project/mdm9x28_1/build_src/tmp/sysroots/x86_64-linux/usr/sbin"

#**********************************************
# Get the config file for UBI
cfg_path=ubinize.cfg

#DM verity on/off
DM_VERITY_ENCRYPT=on

#**********************************************
Usage_help() {
    echo ""
    echo "Usage:"
    echo "./scripts image_folder"
    echo ""
}

Wanning_msg() {
    echo "*************Wanning!*******************"
    echo ""
    echo "Wanning! TOOL_PATH is not defined!"
    echo ""
    echo "*************Wanning!*******************"
}

create_ubinize_config() {
    local cfg_path=$1
    local image_type=$2
    local dm_hash_path=$3
    local dm_root_hash_path=$4
    local image_path=$5

    echo \[sysfs_volume\] > $cfg_path
    sync
    echo mode=ubi >> $cfg_path
    echo image="$image_path" >> $cfg_path
    echo vol_id=0 >> $cfg_path

    if [[ "${image_type}" = "squashfs" ]]; then
        echo vol_type=static >> $cfg_path
    else
        echo vol_type=dynamic >> $cfg_path
        echo vol_size="${UBI_ROOTFS_SIZE}" >> $cfg_path
    fi

    echo vol_name=rootfs >> $cfg_path
    echo vol_alignment=1 >> $cfg_path

    if [[ "${DM_VERITY_ENCRYPT}" = "on" ]]; then
        # dm-verity hash tree table followed after the rootfs
        # Init scripts will check this partition during boot up
        if [[ -s ${dm_hash_path} ]]; then
            echo >> $cfg_path
            echo \[hash_volume\] >> $cfg_path
            echo mode=ubi >> $cfg_path
            echo image="$dm_hash_path" >> $cfg_path
            echo vol_id=1 >> $cfg_path
            echo vol_type=static >> $cfg_path
            echo vol_name=rootfs_hs >> $cfg_path
            echo vol_alignment=1 >> $cfg_path
        fi

        #  dm-verity root hash is following the hash
        if [[ -s ${dm_root_hash_path} ]]; then
            echo >> $cfg_path
            echo \[rh_volume\] >> $cfg_path
            echo mode=ubi >> $cfg_path
            echo image="$dm_root_hash_path" >> $cfg_path
            echo vol_id=2 >> $cfg_path
            echo vol_type=static >> $cfg_path
            echo vol_name=rootfs_rhs >> $cfg_path
            echo vol_alignment=1 >> $cfg_path
        fi
    fi
    sync
}

# Create hash tree table bin file
create_dm_verity_hash() {
    local image_path=$1
    local dm_hash_path=$2
    local dm_hash_filename=$3
    local dm_args=$4

    # We should save the format log to ${dm_hash_path}.txt,
    # So the other scripts can get require info from it
    if [ "x$TOOL_PATH" != "x" ]; then
        ${TOOL_PATH}/veritysetup format $image_path $dm_hash_path $dm_args > ${dm_hash_filename}
    else
        Wanning_msg
        veritysetup format $image_path $dm_hash_path $dm_args > ${dm_hash_filename}
    fi
}

get_dm_root_hash() {
    local dm_root_hash_path=$1
    local dm_hash_filename=$2
    local root_hash=
    root_hash=$(cat ${dm_hash_filename} | grep Root | awk -F' ' '{printf $3}')
    echo ${root_hash} > ${dm_root_hash_path}
    sync
}

create_img(){
    local rootfs_path=$1
    local image_type=squashfs

    local image_path=${rootfs_path}.${image_type}
    local dm_hash_path=hash.bin
    local dm_hash_filename=hash.txt
    local dm_root_hash_path=rhash.bin

    # Clean not used image first.
    rm -rf ${image_path} ${dm_hash_path} ${dm_hash_filename} ${dm_root_hash_path} ${cfg_path} 
    sync

    # output rootfs.squashfs
    if [ "x$TOOL_PATH" != "x" ]; then
        ${TOOL_PATH}/mksquashfs $rootfs_path $image_path -noappend
    else
        Wanning_msg
        mksquashfs $rootfs_path $image_path -noappend
    fi

    create_dm_verity_hash ${image_path} ${dm_hash_path} ${dm_hash_filename}
    get_dm_root_hash ${dm_root_hash_path} ${dm_hash_filename}
    create_ubinize_config ${cfg_path} ${image_type} ${dm_hash_path} ${dm_root_hash_path} ${image_path}
}


#**********************************************

if [ "x$TOOL_PATH" = "x" ]; then
    Wanning_msg
    exit 1
fi

if [ "x$2" != "x" ]||[ "x$1" = "x" ];then
    Usage_help
    exit 1
fi

create_img $1

#**********************************************
#get UBI image "rootfs.squashfs.ubi"
# For 4k nand flash
# output rootfs.squashfs
if [ "x$TOOL_PATH" != "x" ]; then
    # For 4k nand flash
    ${TOOL_PATH}/ubinize -v -o $1.squashfs.4k.ubi -m 4096 -p 256KiB -s 4096 $cfg_path
    # For 2k nand flash
    ${TOOL_PATH}/ubinize -v -o $1.squashfs.2k.ubi -m 2048 -p 128KiB -s 2048 $cfg_path
else
    Wanning_msg
    # For 4k nand flash
    ubinize -v -o $1.squashfs.4k.ubi -m 4096 -p 256KiB -s 4096 $cfg_path
    # For 2k nand flash
    ubinize -v -o $1.squashfs.2k.ubi -m 2048 -p 128KiB -s 2048 $cfg_path
fi
