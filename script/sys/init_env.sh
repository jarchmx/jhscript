#!/bin/sh
# Save and restore the state of tmux sessions and windows.
# TODO: persist and restore the state & position of panes.

CURRENT_PROG_DIR=$(dirname `realpath $0`)
MAIN_DIR=$(realpath $CURRENT_PROG_DIR/../../)
#SCRIPT_DIR="$MAIN_DIR/script/"

# src_file, target_dir
#ENV_CONF="\
LK_FILES="\
    env/.netrc,$HOME \
    env/.gitconfig,$HOME \
    env/.vimrc,$HOME \
    env/.bashrc,$HOME \
    env/ssh/config,$HOME/.ssh \
    cfg/eclipse_template,$HOME/workspace/ \
    script/sys/tmux-session,$HOME/bin/ \
    script/vpn/forti.sh,$HOME/bin/ \
    script/security/pil-splitter.py,$HOME/bin/ \
    script/security/parsecerts.sh,$HOME/bin/ \
    script/module/ramdump-parser.sh,$HOME/bin/ \
    script/sys/tmux-session,/usr/bin/,sudo \
    env/service/tmux.service,/lib/systemd/system/,sudo \
"

RUN_COMMANDS=" \
    sudo systemctl enable tmux, \
"

link_files()
{
    for lk in $LK_FILES
    do
        set `echo $lk | awk -F',' '{printf("%s %s %s\n",$1,$2,$3)}'`
        src_file=$MAIN_DIR/$1
        target_dir=$2
        sys_sudo=$3
        target_file=$target_dir/$(basename $1)
        [ -L $target_file ] && $sys_sudo rm -f $target_file
        [ ! -d $target_dir ] && $sys_sudo mkdir -p $target_dir
        $sys_sudo ln -sf $src_file $target_file
    done
}

run_commands()
{
    echo $RUN_COMMANDS | awk 'BEGIN{FS=",";count=1} {for(i=1;i<=NF;i++) { system($i)}}'
}

link_files

run_commands
