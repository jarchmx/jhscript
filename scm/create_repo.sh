#!/bin/sh


export GERRIT_SRV=$USER@gerrit.askey.cn
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


for ori_git in `find $SRC_DIR -name '*.git'`
do

    [ ! -d $ori_git ] && continue

    tgt=$prefix/${ori_git#$SRC_DIR/}
    #tgt=${tmp%/.git}.git
    
    cd $ori_git

    ssh $GERRIT_SRV -p $GERRIT_PORT gerrit create-project $tgt
    ssh $GERRIT_SRV -p $GERRIT_PORT gerrit set-project-parent --parent mirror-project-permission-base $tgt
    #git push ssh://$GERRIT_SRV:$GERRIT_PORT/$tgt refs/heads/*
    #git push ssh://$GERRIT_SRV:$GERRIT_PORT/$tgt refs/remotes/*
    #git push ssh://$GERRIT_SRV:$GERRIT_PORT/$tgt refs/tags/*
    #read
    
done

popd &>/dev/null
