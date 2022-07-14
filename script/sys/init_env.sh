#!/bin/sh

CURRENT_PROG_DIR=$(dirname `realpath $0`)
MAIN_DIR=$(realpath $CURRENT_PROG_DIR/../../)

COMMANDS_LIST="\
    ln -sf $MAIN_DIR/env/.netrc $HOME, \
    ln -sf $MAIN_DIR/env/.gitconfig $HOME, \
    ln -sf $MAIN_DIR/env/.vimrc $HOME, \
    ln -sf $MAIN_DIR/env/.bashrc $HOME, \
    mkdir -p $HOME/.ssh, \
    mkdir -p $HOME/bin/, \
    ln -sf $MAIN_DIR/env/ssh/config $HOME/.ssh, \
    chmod 0600 $HOME/.ssh/config, \
    mkdir -p $HOME/workspace/,\
    ln -sf $MAIN_DIR/cfg/eclipse_template $HOME/workspace/, \
    ln -sf $MAIN_DIR/script/sys/tmux-session $HOME/bin/, \
    ln -sf $MAIN_DIR/script/vpn/forti.sh $HOME/bin/, \
    ln -sf $MAIN_DIR/script/security/pil-splitter.py $HOME/bin/, \
    ln -sf $MAIN_DIR/script/security/parsecerts.sh $HOME/bin/, \
    ln -sf $MAIN_DIR/script/module/ramdump-parser.sh $HOME/bin/, \
    sudo rm -f /usr/bin/tmux-session, \
    sudo cp $MAIN_DIR/script/sys/tmux-session /usr/bin/, \
    mkdir -p $HOME/.config/systemd/user/, \
    rm -f $HOME/.config/systemd/user/tmux.service, \
    cp $MAIN_DIR/env/service/tmux.service $HOME/.config/systemd/user/, \
    systemctl --user enable tmux, \
"

run_commands()
{
    echo $COMMANDS_LIST | awk 'BEGIN{FS=",";count=1} \
    { \
        for(i=1;i<=NF;i++)\
        { \
            rc=system($i) \
        }\
    }'
}


run_commands
