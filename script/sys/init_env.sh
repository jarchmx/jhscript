#!/bin/sh
# Save and restore the state of tmux sessions and windows.
# TODO: persist and restore the state & position of panes.

CURRENT_PROG_DIR=$(dirname `realpath $0`)
MAIN_DIR=$(realpath $CURRENT_PROG_DIR/../../)
SCRIPT_DIR="$MAIN_DIR/script/"
ENV_DIR="$MAIN_DIR/env/"

SYS_SCRIPTS="\
	sys/tmux_init \
	sys/tmux-session \
	vpn/forti.sh \
	security/pil-splitter.py \
	security/parsecerts.sh \
	module/ramdump-parser.sh \
"

# src_file, target_dir
ENV_CFG="\
   .netrc,$HOME \
   .gitconfig,$HOME \
   .commit_message_format,$HOME \
   .vimrc,$HOME \
   .bashrc,$HOME \
   ssh/config,$HOME/.ssh \
"

link_sys_scripts()
{
    [ ! -d $HOME/bin ] && mkdir $HOME/bin
    
    for script in $SYS_SCRIPTS
    do
        [ -f $HOME/bin/$script ] && rm -f $HOME/bin/$script
        ln -sf $SCRIPT_DIR/$script $HOME/bin/
    done
}

link_env_cfg()
{
    for cfg in $ENV_CFG
    do
        set `echo $cfg | awk -F',' '{printf("%s %s\n",$1,$2)}'`
        src_file=$ENV_DIR/$1
        target_dir=$2
        [ ! -d $target_dir ] && mkdir -p $target_dir
        ln -sf $src_file $target_dir/
    done
}


link_sys_scripts

link_env_cfg
