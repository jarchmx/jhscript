#!/bin/sh

usage()
{
    echo "Usage:"
    echo "Create mirror repositories from git repos in a directory"
    echo "  $0 in_dir [out_dir]"
    echo "     in_dir: in directory include multi git repositories"
    echo "     out_dir: output dir, default is in_dir.mirror "
    exit 1
}


[ $# -lt 1 ] && usage

INDIR=$1

[ x"$2" != x ] && OUTDIR=$2 || OUTDIR=`basename $INDIR`.mirror

echo INDIR:$INDIR OUTDIR:$OUTDIR

[ -d $OUTDIR ] && rm -rf $OUTDIR
[ ! -d $OUTDIR ] && mkdir -p $OUTDIR

pushd $INDIR &>/dev/null
SRC_DIR=`pwd`
popd &>/dev/null

pushd $OUTDIR &>/dev/null


for ori_git in `find $SRC_DIR -name '.git'`
do

    [ ! -d $ori_git ] && continue

    tmp=${ori_git#$SRC_DIR/}
    tgt=${tmp%/.git}.git
    
    src=${ori_git%/.git}

    rm -rf $tgt
    echo git clone --mirror $src $tgt
    git clone --mirror $src $tgt &>/dev/null

    cd $src &>/dev/null
    url=`git remote get-url $(git remote)`
    cd - &>/dev/null
    
    cd $tgt &>/dev/null

    #echo "Before remote update"
    #tree refs/
    echo "update $tgt from $url"
    git remote remove $(git remote)
    #remove local branches.
    bns=`git branch | tr -d '\*'` 
    git branch -D $bns;
    
    git remote add origin $url
    git remote update
    #echo "After remote update"
    #tree refs/
    cd - &>/dev/null
    
done

popd &>/dev/null
