#!/bin/sh

usage()
{
    echo "Usage:"
    echo "    $0 <src dir> <target root dir>"
    echo "    src dir: the source dir include all repo dir or git repository for project"
    echo "    target root dir: the target to sync"
    exit 1
}

usage()
{
    cat << EOF
Usage:
$0 <options ...>

  Global:
    -s <src_dir>
    -t <target_root_dir>
    -h this hekp

  Notes:
    src_dir: the source dir include all repo dir or git repository for project"
    target_root_dir: the target root directory to sync
EOF
    exit 1
}

while getopts "s:t:h" arg
do
    case $arg in
    s)
        export srcdir=$OPTARG
        echo "srcdir: $srcdir"
        [ ! -d $srcdir ] && echo "$srcdir not exist" && exit 1
        ;;
    t)
        export tgtroot=$OPTARG
        echo "target root: $tgtroot"
        #[ ! -d $tgtroot ] && echo "$tgtroot not exist" && exit 1
        ;;
    h)
        usage
        ;;
    ?)
        echo "$0: invalid option -$OPTARG" 1>&2
        usage
        ;;
    esac
done

function error_handler()
{
    echo "$*"
    exit 1
}

[ x"$srcdir" == "x" ] && usage
[ x"$tgtroot" == "x" ] && usage

REALSRC=`realpath $srcdir`
BASESRC=`basename $srcdir`

cd $REALSRC

LOGPATH=$(dirname $REALSRC)/logs/

[ ! -d $LOGPATH ] && mkdir -p $LOGPATH
LOGFILE="$LOGPATH"/"$BASESRC"_$(date +%Y%m%d%H%M%S).log

sync_all()
{
    for gits in `ls $REALSRC`
    do
        #sync repos.
        if [ -d $gits/.repo ];then
            #get prefix from gits, Ex: caf_qti -> qti
            echo $update $gits
            export prefix=`echo $gits |awk -F'_' '{print $2}'`
            cd $gits
            repo sync
            #repo forall -c 'git push --mirror -v $tgt'
            #repo forall -c 'tgt=$tgtroot/$prefix/$REPO_PROJECT.git ; echo push $REPO_PROJECT.git to $tgt; git push --all -v $tgt || exit 1'
            repo forall -c 'tgt=$tgtroot/$prefix/$REPO_PROJECT.git ; echo git push --all $prefix/$REPO_PROJECT.git to $tgt; git push --all -v $tgt'
            cd -
        else
            prefix=$gits
            for git in `find $gits -type d -name *.git`
            do
                echo $update $git
                tgt=$tgtroot/$git
                echo tgt:$tgt
                #[ ! -d $tgt ] && error_handler "$tgt not exist";
                cd $git
                #git remote update
                git fetch origin --tags +refs/heads/*:refs/remotes/origin/*
                echo push $git to $tgt
                #echo git push --all -v $tgt
                echo git push --all $tgt 
                #git push --all -v $tgt || error_handler "Update $tgt fail"
                git push --all -v $tgt  || echo "run git push --all -v $tgt fail"
                cd -
            done
        fi
    done
}

sync_all 2>&1 | tee $LOGFILE

exit 0
