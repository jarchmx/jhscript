#!/bin/sh

export GERRIT_SRV=$USER@gerrit.askey.cn
export GERRIT_PORT=29418


#git fetch origin  +refs/heads/*:refs/remotes/origin/*

#ssh $GERRIT_SRV -p $GERRIT_PORT gerrit ls-projects
#repo forall -c 'ssh $GERRIT_SRV -p $GERRIT_PORT gerrit create-project qti/$REPO_PROJECT'
#repo forall -c 'ssh $GERRIT_SRV -p $GERRIT_PORT gerrit set-project-parent --parent mirror-project-permission-base qti/$REPO_PROJECT'
#repo forall -c 'git push --mirror ssh://$GERRIT_SRV:$GERRIT_PORT/qti/$REPO_PROJECT'
#repo forall -c 'git push ssh://$GERRIT_SRV:$GERRIT_PORT/qti/$REPO_PROJECT refs/heads/*'
#repo forall -c 'git push ssh://$GERRIT_SRV:$GERRIT_PORT/qti/$REPO_PROJECT refs/remotes/*'
#repo forall -c 'git push ssh://$GERRIT_SRV:$GERRIT_PORT/qti/$REPO_PROJECT refs/tags/*'


sync()
{
    #source dir.
    srcdir=$1
    #prefix.
    pf=$2
    cd $srcdir
    
    #repo sync
    if [ -d .repo ];then
        #repo sync
        repo forall -c 'git push ssh://$GERRIT_SRV:$GERRIT_PORT/$pf/$REPO_PROJECT refs/heads/*'
        #repo forall -c 'git push ssh://$GERRIT_SRV:$GERRIT_PORT/$pf/$REPO_PROJECT refs/tags/*'
    elif [ -d .git ];then
        git remote update
        echo git push ssh://$GERRIT_SRV:$GERRIT_PORT/$pf/$srcdir refs/heads/*
        git push ssh://$GERRIT_SRV:$GERRIT_PORT/$pf/$srcdir refs/heads/*
        echo git push ssh://$GERRIT_SRV:$GERRIT_PORT/$pf/$srcdir refs/tags/*
        git push ssh://$GERRIT_SRV:$GERRIT_PORT/$pf/$srcdir refs/tags/*
    fi

    cd -
}

for n in `ls`
do
    sync $n qti
done
