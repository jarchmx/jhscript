#!/bin/sh

usage()
{
    echo "Usage:"
    echo "Create mirror repositories from git repos in a directory"
    echo "  $0 in_dir [server_prefix] [path_prefix]"
    echo "     in_dir: in directory include multi git repositories"
    echo "     server_prefix: server uri prefix on gerrit server"
    echo "     path_prefix: local path prefix."
    exit 1
}


[ $# -lt 1 ] && usage

INDIR=$1

[ x"$2" != x ] && serv_pf=$2
[ x"$3" != x ] && local_pf=$3


pushd $INDIR &>/dev/null
SRC_DIR=`pwd`

echo "Please copy the below contents to manifest!!!"
echo "<!--========================================================================-->"
echo "<!-- NXP LSSDK packages -->"

for ori_git in `find $SRC_DIR -name '.git'`
do

    [ ! -d $ori_git ] && continue

    tmp=${ori_git#$SRC_DIR/}
    tgt=${tmp%/.git}
    
    cd $tgt &>/dev/null
    
    REV=`git rev-parse HEAD`
    BR=`git branch | grep '^\*' | awk '{print $2}'`

    #echo "<project name=\"$serv_pf/$tgt\" path=\"$local_pf/$tgt\" upstream=\"refs/heads/$BR\" groups=\"default,lssdk,internal\" revision=\"$REV\" />"
    echo "<project name=\"$serv_pf/$tgt\" path=\"$local_pf/$tgt\" groups=\"default,lssdk,internal\" revision=\"$REV\" />"


    cd - &>/dev/null
    
done

popd &>/dev/null
