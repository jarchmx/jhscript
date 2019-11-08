#!/bin/bash

#The files should be splitted into nand/bin/image.
splitter_files=" \
sdx55/SDX55_tz/trustzone_images/build/ms/bin/EATAANBA/cmnlib.mbn \
sdx55/SDX55_modem/modem_proc/build/ms/bin/sdx55.gennatch.prod/qdsp6sw.mbn \
sdx55/SDX55_tz/trustzone_images/build/ms/bin/EATAANBA/cmnlib64.mbn \
build_src/tmp/deploy/images/swi-sdx55/ipa-fws/ipa_fws.elf"

#The files should copy to nand/bin/image.
cp_files=" \
sdx55/common/build/Ver_Info.txt \
sdx55/SDX55_btfm/btfm_proc/bt/build/ms/bin/QCA6690/htbtfw10.tlv \
sdx55/SDX55_btfm/btfm_proc/bt/build/ms/bin/QCA6690/htbtfw20.tlv
sdx55/SDX55_btfm/btfm_proc/bt/build/ms/bin/QCA6690/htnv10.bin \
sdx55/SDX55_btfm/btfm_proc/bt/build/ms/bin/QCA6690/htnv20.bin \
sdx55/SDX55_modem/modem_proc/build/ms/servreg/sdx55.gennatch.prodQ/modemr.jsn \
sdx55/SDX55_wlan_hst/wlan_proc/wlan/phyrf_svc/tools/bdfUtil/device/bdf/qca639x/bdwlan.e0a \
sdx55/SDX55_wlan_hst/wlan_proc/config/bsp/cnss_ram_v2_TO_link_patched/build/6390.wlanfw.eval_v2_TO/amss20.bin \
sdx55/SDX55_wlan_hst/wlan_proc/wlan/phyrf_svc/tools/bdfUtil/device/bdf/qca639x/bdwlan.elf \
sdx55/SDX55_wlan_hst/wlan_proc/wlan/phyrf_svc/tools/bdfUtil/device/bdf/qca639x/bdwlan.e11 \
sdx55/SDX55_wlan_hst/wlan_proc/wlan/phyrf_svc/tools/bdfUtil/device/bdf/qca639x/bdwlan.e01 \
sdx55/SDX55_wlan_hst/wlan_proc/wlan/subsys/phyucode_binary/image_hastings/m3.bin \
sdx55/SDX55_wlan_hst/wlan_proc/wlan/phyrf_svc/tools/bdfUtil/device/bdf/qca639x/bdwlan.e03 \
sdx55/SDX55_wlan_hst/wlan_proc/wlan/phyrf_svc/tools/bdfUtil/device/bdf/qca639x/bdwlan.e04 \
sdx55/SDX55_wlan_hst/wlan_proc/wlan/phyrf_svc/tools/bdfUtil/device/bdf/qca639x/bdwlan.e05"

usage()
{
    cat << EOF
Usage:
$0 <options ...>

  Global:
    -w <workspace dir>
    -o <out dir>
    -s <sectool dir>
	-c <sec image confing under sectooldir Ex: config/sdx55/sdx55_secimage.xml >
EOF
    exit 1
}

cp_splitter_files()
{
    img=$1
    
    [ ! -f $img ] && echo "$img not exist" && exit 1
	
	basename=`basename $img`
	base=`basename $img | awk -F. '{print $1}'`
	
	if [ $base == "qdsp6sw" ];then
		base="modem"
	fi	
		
	$WORKSPACE/sdx55/common/config/storage/pil-splitter.py $img $outdir/nand/bin/image/$base
	[ $? -ne 0 ] && echo "pil-splitter.py $image fail" && exit 1
}

sign_img()
{
    img=$1
    
    [ ! -f $img ] && echo "$img not exist" && exit 1
	
	basename=`basename $img`
	base=`basename $img | awk -F. '{print $1}'`

	secargs=""
    if [ $basename == "sbl1.mbn" ];then
        secargs="-g sbl1_nand"
		base="sbl1_nand"
	elif [ $basename == "xbl_cfg.elf" ];then
		secargs="-g xbl_config"
		base="xbl_config"
	elif [ $basename == "ipa_fws.elf" ];then
		base="ipa_fw"
	elif [ $basename == "qdsp6sw.mbn" ];then
		base="modem"
		basename="modem.mbn"
	elif [ $basename == "sec.elf" ];then	
		base="secelf"
	fi

    echo "Sign command: python $sectool secimage -s -i $img -c $seccfg -sa $secargs -o $outdir"
    python $sectool secimage -s -i $img -c $seccfg -sa $secargs -o $outdir
    [ $? -ne 0 ] && echo "Sign $image fail" && exit 1	
		
	#override the origin files with new signed file.	
	cp $outdir/sdx55/$base/$basename $img
	[ $? -ne 0 ] && echo "override $img fail" && exit 1
}


#secdir=/home/jarhu/work/Ferrari_EM9190/security/sectools/
seccfg=
while getopts "w:o:s:c:" arg
do
    case $arg in
    w)
        WORKSPACE=$OPTARG
        echo "WORKSPACE: $WORKSPACE"
        [ -z $WORKSPACE ] && usage
        [ ! -d $WORKSPACE ] && usage
        [ ! -f $WORKSPACE/sdx55/SDX55_tz/trustzone_images/build/ms/bin/EATAANBA/cmnlib.mbn ] && echo "Please build sdx55 first" &&  usage
        ;;
    o)
        outdir=$OPTARG
        [ ! -d $outdir ] && mkdir -p $outdir
        ;;
    s)
        secdir=$OPTARG
        [ ! -d $secdir ] && echo "$secdir not exit" && exit 1
        sectool=$secdir/sectools.py
        [ ! -f $sectool ] && echo "$sectool not exist" && exit 1 
        ;;
    c)
        seccfg=$OPTARG
        ;;
    ?)
        echo "$0: invalid option -$OPTARG" 1>&2
        usage
        ;;
    esac
done

if [ x$seccfg != "x" ];then
    seccfg=$secdir/$seccfg
else
    seccfg="$secdir/config/sdx55/sdx55_secimage.xml"
fi

[ ! -f $seccfg ] && echo "$seccfg not exist" && exit 1

[ -z $outdir ] && outdir=outdir



mkdir -p $outdir/nand/bin/image

#get the needed sign files list.
python $sectool secimage -p sdx55 -m $WORKSPACE/sdx55/ --m_gen --m_sign --m_validate --no_op -o $outdir/nand/multi_image/ 2>&1 | tee sign.log
[ $? -ne 0 ] && exit 1

sign_files=`cat sign.log | grep ^Processing  | awk -F: '{print $2}'`
#rm -f sign.log
#Added sec.elf to sign_files list.
sign_files="$sign_files  $WORKSPACE/sdx55/common/config/sec/sec.elf"
for file in $sign_files
do
	echo "Signing : $file"
	sign_img $file
done

#generate the multi image with re-signed files.
rm -rf $outdir/nand/multi_image/
python $sectool secimage -p sdx55 -m $WORKSPACE/sdx55/ --m_gen --m_sign --m_validate --no_op -o $outdir/nand/multi_image/
[ $? -ne 0 ] && exit 1
cp $outdir/nand/multi_image/sdx55/multi_image/multi_image.mbn $WORKSPACE/sdx55/common/build/nand/multi_image.mbn
[ $? -ne 0 ] && exit 1

#generate debugpolicy image and sign
python $sectool debugpolicy -p sdx55 -gsa -i dbgp_ap -o $outdir/nand/apdp/
[ $? -ne 0 ] && exit 1
cp $outdir/nand/apdp/apdp.mbn  $WORKSPACE/sdx55/common/build/nand/apdp/
[ $? -ne 0 ] && exit 1


for file in $splitter_files
do
	echo "copy signed file: $WORKSPACE/$file"
	cp_splitter_files $WORKSPACE/$file
done

for file in $cp_files
do
	echo "Copy $WORKSPACE/$file to $outdir/nand/bin/image"
	cp $WORKSPACE/$file $outdir/nand/bin/image
	[ $? -ne 0 ] && exit 1
done

#other files should copy to nand/bin/image.
cp $WORKSPACE/sdx55/SDX55_wlan_hst/wlan_proc/wlan/phyrf_svc/tools/bdfUtil/device/bdf/qca639x/bdwlan.elf $outdir/nand/bin/image/bdwlan.e0d
[ $? -ne 0 ] && exit 1
mkdir -p $outdir/nand/bin/image/sdx55/
[ $? -ne 0 ] && exit 1
cp $WORKSPACE/sdx55/SDX55_modem/modem_proc/build/ms/bin/sdx55.gennatch.prod/qdsp6m.qdb $outdir/nand/bin/image/sdx55
[ $? -ne 0 ] && exit 1

#generate modem_pr  files.
python $WORKSPACE/sdx55/SDX55_modem/modem_proc/mcfg/mcfg_gen/scripts/mcfg_meta.py -cx $WORKSPACE/sdx55/contents.xml -mp $outdir/nand/bin/image/modem_pr -mr $WORKSPACE/sdx55/ -bf sdx55.gennatch.prod -ch SDX55 -pt STANDALONE


cd $outdir/nand
$WORKSPACE/sdx55/common/config/storage/mksquashfs bin NON-HLOS.squashfs -noappend
[ $? -ne 0 ] && exit 1

$WORKSPACE/sdx55/SDX55_apps/../common/config/storage/ubinize -v -o NON-HLOS.ubi -m 4096 -p 256KiB -s 4096 $WORKSPACE/sdx55/common/config/storage/my_ubi.ini
[ $? -ne 0 ] && exit 1
cp NON-HLOS.ubi $WORKSPACE/sdx55/common/build/nand/

#check md5sum of workspace and outdir.
cd -
#cat sign.log | grep ^Process | awk -F: '{print $2}' >files
for file in `cat sign.log | grep ^Process | awk -F: '{print $2}'` ; do basename=`basename $file` ; \
[ $basename == "qdsp6sw.mbn" ] && basename=modem.mbn ;sfile=`find . -name "$basename"` ; md5sum $file $sfile ; done
md5sum $outdir/nand/NON-HLOS.ubi $WORKSPACE/sdx55/common/build/nand/NON-HLOS.ubi
md5sum $outdir/nand/multi_image/sdx55/multi_image/multi_image.mbn $WORKSPACE/sdx55/common/build/nand/multi_image.mbn
md5sum $outdir/nand/apdp/apdp.mbn  $WORKSPACE/sdx55/common/build/nand/apdp/apdp.mbn
