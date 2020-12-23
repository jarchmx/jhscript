#!/bin/sh

export GERRIT_SRV=$USER@gerrit.askey.cn
export GERRIT_PORT=29418


ssh $GERRIT_SRV -p $GERRIT_PORT gerrit ls-projects
repo forall -c 'ssh $GERRIT_SRV -p $GERRIT_PORT gerrit create-project qti/$REPO_PROJECT'
repo forall -c 'ssh $GERRIT_SRV -p $GERRIT_PORT gerrit set-project-parent --parent mirror-project-permission-base qti/$REPO_PROJECT'
#repo forall -c 'git push --mirror ssh://$GERRIT_SRV:$GERRIT_PORT/qti/$REPO_PROJECT'
repo forall -c 'git push ssh://$GERRIT_SRV:$GERRIT_PORT/qti/$REPO_PROJECT refs/heads/*'
repo forall -c 'git push ssh://$GERRIT_SRV:$GERRIT_PORT/qti/$REPO_PROJECT refs/remotes/*'
repo forall -c 'git push ssh://$GERRIT_SRV:$GERRIT_PORT/qti/$REPO_PROJECT refs/tags/*'
