#!/bin/sh


export GERRIT_SRV=$USER@10.8.16.158
export GERRIT_PORT=29418

usage()
{
    echo "Usage:"
    echo "Create Gerrit repositories from git repos in a directory"
    echo "  $0 in_dir [prefix]"
    echo "     in_dir: in directory include multi git mirror repositories"
    echo "     prefix: the prefix on the server"
    exit 1
}


[ $# -lt 1 ] && usage

INDIR=$1

[ x"$2" != x ] && prefix=$2

pushd $INDIR &>/dev/null
SRC_DIR=`pwd`
popd &>/dev/null

flag=0

set -x

for ori_git in `find $SRC_DIR -name '*.git'`
do

    [ ! -d $ori_git ] && continue

    tgt=$prefix/${ori_git#$SRC_DIR/}
    #tgt=${tmp%/.git}.git
    
    cd $ori_git

    ssh $GERRIT_SRV -p $GERRIT_PORT gerrit create-project $tgt
    ssh $GERRIT_SRV -p $GERRIT_PORT gerrit set-project-parent --parent mirror-project-permission-base $tgt
    #echo push heads
    #git push ssh://$GERRIT_SRV:$GERRIT_PORT/$tgt refs/heads/*
    #echo push remotes
    #git push ssh://$GERRIT_SRV:$GERRIT_PORT/$tgt refs/remotes/*
    #echo push tags
    #git push ssh://$GERRIT_SRV:$GERRIT_PORT/$tgt refs/tags/*
    #git push --mirror ssh://$GERRIT_SRV:$GERRIT_PORT/$tgt
    if [ $flag -eq 0 ];then
        let flag+=1
        read
    fi
done

popd &>/dev/null
