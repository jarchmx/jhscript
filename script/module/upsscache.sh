#!/bin/sh


usage()
{
    echo 'Usage:'
    echo '    Please notice that this script run under yocto build directory.'
    echo '    $0 <yocto_version>'
    echo '    yocto_version: 1.7 or 2.2'
    echo 'Ex:'
    echo '    $0 1.7'
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

VER=$1
DIR=$2

if [[ $VER != "1.7" && $VER != "2.2" ]];then
    echo "$VER is Not 1.7 or 2.2 yocto version"
    usage
fi

if [ ! -f conf/local.conf ];then
    echo "Not in build directory."
    usage
fi

SSDIR_TMP=`grep -n ^SSTATE_DIR conf/local.conf 2>/dev/null`
if [ $? -eq 0 ] ; then
    LINE=`echo $SSDIR_TMP | awk -F: '{print $1}'` 
    SSDIR_LINE=`echo $SSDIR_TMP | awk -F: '{print $2}'`
    SSDIR=`echo $SSDIR_LINE | awk -F= '{print $2}'`
    echo "modify SSTATE_DIR from $SSDIR to ~/sstate-cache/$VER"
    sed -i "N;$LINE a SSTATE_DIR ?= \"/home/jarhu/sstate-cache/1.7\"" ./conf/local.conf
    sed -i "$LINE d" $DIR/conf/local.conf
else
    echo "add SSTATE_DIR to ~/sstate-cache/$VER"
    echo SSTATE_DIR ?= \"/home/jarhu/sstate-cache/"$VER"\" >>./conf/local.conf
fi
