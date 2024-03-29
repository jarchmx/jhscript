# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
#case "$TERM" in
#    xterm-color|*-256color) color_prompt=yes;;
#esac
color_prompt=yes

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

export PATH=$PATH:/sbin/:/opt/eclipse:$HOME/bin:/mnt/d/sw/android/adb_new/

if ! tmux ls &>/dev/null ;then tmux-session restore &>/dev/null ; fi

function mc_usage()
{
cat << EOF
    mc<minicom connect>

    connect to serial port, create socat seciral device if device not exit.
    ========================================================================================================
    Usage: mc [options]
    ========================================================================================================
    Options:

    -d/--dev: device to attach, default ttyUSB0.

    -b/--baud: baudrate, default is 115200.

    -p/--port: socat port to connect serial server,default is 3003.

    -i/--ip:   socat ip to connect serial server, default is 10.8.16.95.

    ========================================================================================================
    Example:
    mc -d ttyUSB2
    mc -d ttyUSB2 -i 10.8.16.95 -p 3003 -b 115200
    ========================================================================================================

EOF

    return 1
}

mc()
{
    DEV="ttyUSB0"
    BAUD="115200"
    SOPORT="3003"
    SOIP="10.8.16.95"
    #PARAMS=$@
    #=======================================
    # script options
    #=======================================
    SHOPT_OPTS="d:b:p:i:h"
    LONG_OPTS="dev:,baud:,port:,ip:,help"

    temp=`getopt -o $SHOPT_OPTS --long $LONG_OPTS -- "$@"`
    if [ $? != 0 ] ; then echo "terminating..." >&2 ; usage ; fi
    # note the quotes around `$temp': they are essential!
    eval set -- "$temp"
    while true ; do
        case $1 in
            -d|--dev)
                DEV=$2
                shift 2
                ;;
            -b|--baud)
                BAUD=$2
                shift 2
                ;;
            -p|--port)
                SOPORT=$2
                shift 2
                ;;
            -i|--ip)
                SOIP=$2
                shift 2
                ;;
            -h|--help)
                mc_usage
                return 1
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "parameters error!"
                mc_usage
                return 1
                ;;
        esac
    done

    LOGPATH=/opt/log/$DEV
    LOGFILE="$LOGPATH"/$(date +%Y%m%d%H%M%S).log
    
    sudo mkdir -p $LOGPATH
    sudo touch $LOGFILE
    sudo ln -sf $LOGFILE "$LOGPATH".log

    if [ ! -c /dev/$DEV ] || realpath /dev/$DEV | grep pts &>/dev/null ;then
        set -x
        [ -c /dev/$DEV ] && sudo unlink /dev/$DEV
        NUM=${DEV:0-1}
        sudo socat pty,link=/dev/$DEV tcp:$SOIP:$SOPORT &
        SOCATPID=$!
        echo SOCATPID:$SOCATPID
        sleep 1
        SOCATPIDS=$(ps -ef | grep $SOCATPID | grep -v grep | awk '{print $2}')
        echo SOCATPIDS:$SOCATPIDS
        set +x
        sleep 1
    fi

    #kill the process opened /dev/$DEV.
    for pid in $(ps aux | grep /dev/$DEV | grep -v grep | grep -v socat | awk '{print $2}')
    do
        sudo kill -9 $pid
    done

    echo minicom -D /dev/$DEV -b $BAUD -w -C $LOGFILE default
    sudo minicom -D /dev/$DEV -b $BAUD -w -C $LOGFILE default

    [ -n "$SOCATPIDS" ] && for pid in $SOCATPIDS ; do  sudo kill -9 $pid ; done
}

ta()
{
    if ! tmux a -t $@ ;then 
        tmux new -s $@
    fi

}

fn()
{
    find -L . -iname "$*"
}

proxy()
{
    #proxy 30389 to slave.gerrit.askey.cn
    ssh -NfL 0.0.0.0:30389:slave.gerrit.askey.cn:30389 jarch_hu@localhost
}

alias ts='tmux switch -t'
#alias ta='tmux a -t'
alias tl='tmux ls'
#alias fastboot='fastboot.exe'
#alias tn='tmux new -s'
alias ec='setsid eclipse &>/dev/null &'
alias fs='fastboot flash system'
alias ff='fastboot flash'
alias fb='fastboot flash boot'
alias fb2='fastboot flash boot2'
alias fr='fastboot reboot'
alias fr1='fastboot oem swi-set-ssid 111 && fastboot reboot'
alias fr2='fastboot oem swi-set-ssid 222 && fastboot reboot'
alias fe='fastboot erase'
alias frfs='fastboot flash system'
alias fu='fastboot oem keep-alive && fastboot oem flash-unlock aepa1du5vae1fahb9enohchie+Neer5t'
alias mountsc='mkdir $HOME/sc_work &>/dev/null ; sudo mount -t nfs 10.8.16.124:/home/jarch_hu/sc_work $HOME/sc_work'
alias mountms='mkdir $HOME/ms &>/dev/null ; sudo mount -t nfs 10.8.16.120:/home/jarch_hu/ms $HOME/ms'
alias mountms2='mkdir $HOME/ms2 &>/dev/null ; sudo mount -t nfs 10.8.16.121:/home/users/jarch_hu/ms2 $HOME/ms2'
alias mountms2_c='mkdir $HOME/ms2 &>/dev/null ; sudo mount -t cifs -o username=jarch_hu,password=123456,uid=$(id -u),gid=$(id -g),actimeo=0 //msc4-u2004/jarch_hu/ms2 $HOME/ms2/'
alias mountms68='mkdir -p $HOME/ms68 &>/dev/null ; sudo mount -t nfs 10.8.16.68:/home/users/jarch_hu/ms68 $HOME/ms68'
alias mountms68_c='mkdir -p $HOME/workspace/SDX6x &>/dev/null ; sudo mount -t cifs -o username=gerrit,password=123456,uid=$(id -u),gid=$(id -g),actimeo=0 //10.8.16.68/gerrit/workspace/SDX6x/ $HOME/workspace/SDX6x'
alias mountsg='mkdir $HOME/sg &>/dev/null ; sudo mount -t nfs 10.8.17.89:/home/jarch_hu/sg $HOME/sg'
alias mountsg_c='mkdir $HOME/nas &>/dev/null ; sudo mount -t cifs -o credentials=$HOME/.smbpass,rw,uid=$(id -u),gid=$(id -g),actimeo=0 //10.8.17.89/jarch_hu/ $HOME/nas'
alias mountmsc1='mkdir $HOME/msc1 &>/dev/null ; sudo mount -t nfs 10.8.17.236:/home/users/jarch_hu/msc1 $HOME/msc1'
alias mountmsc1_z='mkdir -p $HOME/zfs/msc1-u2004-data &>/dev/null ; sudo zfs set mountpoint=$HOME/zfs/msc1-u2004-data data/custom/default_msc1-u2004-data ; sudo zfs mount data/custom/default_msc1-u2004-data'
alias mountmsc1_c='mkdir -p $HOME/msc1 &>/dev/null ; sudo mount -t cifs -o credentials=$HOME/.smbpass,rw,uid=$(id -u),gid=$(id -g),actimeo=0 //msc1-u2004/jarch_hu/msc1 $HOME/msc1/'
alias mountnas='mkdir $HOME/File &>/dev/null ; sudo mount -t cifs -o credentials=$HOME/.smbpass_askey -o rw,uid=$(id -u),gid=$(id -g),actimeo=0 //askeysz_nas/File $HOME/File/'
alias gnome-terminal="gnome-terminal --disable-factory"
alias eclipse='eclipse &>/dev/null &'
alias pwonlaptop='wakeonlan B0:5C:DA:DD:95:35'

#gerrit
alias gcp='ssh mgerrit gerrit create-project '
alias gsp='ssh mgerrit gerrit set-project-parent -p '
alias glp='ssh mgerrit gerrit ls-projects '

#alias fn='find . -iname '
alias gn='grep -nr'
alias gi='grep -inr'

#ssh
alias ssh='ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
alias scp='scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'

export T32SYS=/opt/t32
export T32TMP=/tmp
export T32ID=T32

export ADOBE_PATH=/opt/Adobe/Reader9/
export ACROBAT_PATH=/opt/Adobe/Reader9

#alias ssh='ssh -X'

ARCH=`uname -m`
[[ $ARCH == "x86_64" && -f ~/.fzf.bash ]] && source ~/.fzf.bash

export RTE_SDK=/home/jarch_hu/work/dpdk/
export RTE_TARGET=x86_64-native-linuxapp-gcc

#docker-compose -f ~/jhscript/cfg/docker/docker-compose.yml up -d --no-recreate

#for gpg sign fail.
#error: gpg failed to sign the data
#error: unable to sign the taG
export GPG_TTY=$(tty)

kill_bitbake()
{
    for n in `ps aux | grep bitbake |grep -v grep | awk '{print $2}'` ; do kill -9 $n ; done
}

gitpush()
{
    set -x
    remote=`git remote`
    dft_branch=`git branch -a | grep '\->' | awk -F'>' '{print $2}' | sed "s/$remote\///g" | tr -d ' ' | tr -d '\n'`
    if [[ x$dft_branch == "x" || x$remote == "x" ]];then
        echo "Can't detect default branch, please check it by \' git branch -a | grep master\'"
        return 1
    fi
    TOPIC=""
    if  git lg -1 | grep HEAD | grep PGTEL &>/dev/null ;then
        JIRA_NUM=$(git lg -1 | grep HEAD | grep PGTEL |sed -e 's/\(^\|.* \)PGTEL-\([^ ]*\) .*/\2/' | awk -F':' '{print $1}')
        JIRA="PGTEL-$JIRA_NUM"
        TOPIC="%topic=$JIRA"
    fi
    git push $remote HEAD:refs/for/$dft_branch$TOPIC $@
    set +x
}

forward_zero()
{
    outgress=$(ip route | grep 10.8 | grep default | awk '{print $5}')
    echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
    sudo iptables -t nat -A POSTROUTING --out-interface $outgress -j MASQUERADE
    #sudo iptables -A FORWARD --in-interface all -j ACCEPT
}

noforward_zero()
{
    echo 0 | sudo tee /proc/sys/net/ipv4/ip_forward
}
#sectools argument autocompletion
pyargcomp=$(which register-python-argcomplete)
[ x$pyargcomp != "x" ] && eval "$(register-python-argcomplete sectools)"
