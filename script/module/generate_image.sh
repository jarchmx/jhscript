#!/bin/sh


prepare_ubi() {
    prepare_ubi_ps '4k'

    cd $outdir

    # Default image (no bs suffix) to 4k + squashfs
    ubi_link_path_def="mdm-image-minimal-swi-sdx55.squashfs.4k.ubi"

    ubi_link_path="mdm-image-minimal-swi-sdx55.4k.ubi"
    ubi_link_path_2k="mdm-image-minimal-swi-sdx55.2k.ubi"

    rm -f $ubi_link_path 
    ln -s $ubi_link_path_def $ubi_link_path

    ubi_link_path="mdm-image-minimal-swi-sdx55.ubi"
    rm -f $ubi_link_path
    ln -s $ubi_link_path_def $ubi_link_path
}

prepare_ubi_ps() {
    local page_size=$1
    local image_type=
    local ubinize_cfg=
    local image_path=
    local dm_hash_path=
    local dm_hash_filename=
    local dm_root_hash_path=
    local ubi_path=
    local ubi_link_path=

    mkdir -p $outdir

    for rootfs_type in squashfs ubifs; do
        image_type=${rootfs_type}

        ubinize_cfg="$outdir/mdm-image-minimal-swi-sdx55.rootfs.${image_type}.ubinize.cfg"
        image_path="$outdir/mdm-image-minimal-swi-sdx55.rootfs.${image_type}"

        create_ubinize_config ${ubinize_cfg} ${image_type}
        sync

        ubi_path="$outdir/mdm-image-minimal-swi-sdx55.${rootfs_type}.${page_size}.ubi"
        create_ubi_image $page_size $ubinize_cfg $ubi_path $ubi_link_path
    done
}

create_ubinize_config() {
    local cfg_path=$1
    local rootfs_type=$2
	local vid=0

    if [[ "off" = "on" ]]; then
        local dm_hash_path=$3
        local dm_root_hash_path=$4
    fi

    local rootfs_path="$outdir/mdm-image-minimal-swi-sdx55.rootfs.${rootfs_type}"

    echo \[sysfs_volume\] > $cfg_path
    echo mode=ubi >> $cfg_path
    echo image="$rootfs_path" >> $cfg_path
    echo vol_id=$vid >> $cfg_path
	let vid+=1
	
    if [[ "${rootfs_type}" = "squashfs" ]]; then
        echo vol_type=static >> $cfg_path
    else
        echo vol_type=dynamic >> $cfg_path
        echo vol_size="100MiB" >> $cfg_path
    fi

    echo vol_name=rootfs >> $cfg_path
    echo vol_alignment=1 >> $cfg_path

    if [[ "off" = "on" ]]; then
        # dm-verity hash tree table followed after the rootfs
        # Init scripts will check this partition during boot up
        if [[ -s ${dm_hash_path} ]]; then
            echo >> $cfg_path
            echo \[hash_volume\] >> $cfg_path
            echo mode=ubi >> $cfg_path
            echo image="$dm_hash_path" >> $cfg_path
            echo vol_id=$vid >> $cfg_path
            echo vol_type=static >> $cfg_path
            echo vol_name=rootfs_hs >> $cfg_path
            echo vol_alignment=1 >> $cfg_path
			let vid+=1
        fi

        #  dm-verity root hash is following the hash
        if [[ -s ${dm_root_hash_path} ]]; then
            echo >> $cfg_path
            echo \[rh_volume\] >> $cfg_path
            echo mode=ubi >> $cfg_path
            echo image="$dm_root_hash_path" >> $cfg_path
            echo vol_id=$vid >> $cfg_path
            echo vol_type=static >> $cfg_path
            echo vol_name=rootfs_rhs >> $cfg_path
            echo vol_alignment=1 >> $cfg_path
			let vid+=1
        fi
    fi
}

create_ubi_image() {
    local page_size=$1

    local ubinize_cfg=$2

    local ubi_path=$3
    local ubi_link_path=$4

    local ubinize_args=''

    case $page_size in
    2k)
        ubinize_args="-m 2048 -p 128KiB -s 2048"
        ;;
    4k)
        ubinize_args="-m 4096 -p 256KiB -s 4096"
        ;;
    *)
        exit 1
        ;;
    esac

    /home/jarhu/work/Ferrari_EM9190/em91_tag/build_src/tmp/work/swi_sdx55-poky-linux-gnueabi/mdm-image-minimal/1.0-r0.0/recipe-sysroot-native/usr/sbin/ubinize -o $ubi_path $ubinize_args $ubinize_cfg

    if [ -n "$ubi_link_path" ]; then
        rm -f $ubi_link_path
        ln -s $(basename $ubi_path) $ubi_link_path
    fi
}

do_image_fs() {
    rootfs_type=$1
    if [ -d $rootfs/.git ];then
        mv $rootfs/.git .git.bak
    fi
    if [ $rootfs_type == "squashfs" ];then
        #fakeroot mksquashfs $rootfs $outdir/mdm-image-minimal-swi-sdx55.rootfs.$rootfs_type -comp xz -noappend
        fakeroot mksquashfs $rootfs $outdir/mdm-image-minimal-swi-sdx55.rootfs.$rootfs_type -noappend
    elif [ $rootfs_type == "ubifs" ];then
        fakeroot /usr/sbin/mkfs.ubifs -r $rootfs -o $outdir/mdm-image-minimal-swi-sdx55.rootfs.$rootfs_type -m 4096 -e 253952 -c 2146 -F
    fi

    if [ -d .git.bak ];then
        mv .git.bak $rootfs/.git
    fi
}

usage()
{
    echo "$0 rootdir outdir"
    exit 1
}

if [ $# -lt 2 ];then
    usage
fi

if [ ! -d $1 ];then
    usage
fi

rootfs=$1
outdir=$2

do_image_fs squashfs
do_image_fs ubifs
prepare_ubi
