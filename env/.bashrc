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
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

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
alias fastboot='fastboot -i 0x1199'

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

export PATH=/opt/usr/bin/eclipse:/opt/usr/bin/:$PATH:/sbin/:/home/$USER/usr/bin/:/home/$USER/jhscript/:/home/$USER/bin

#for adb/fastboot.exe
export PATH=$PATH:/mnt/e/sw/android/adb_new/

#if ! tmux ls &>/dev/null ;then tmux-session restore &>/dev/null ; fi

mc()
{
    if [ x"$1" == "x" ];then
       echo "Please run minicom1 with dev"
       return 1
    fi

    DEV=$1
    BAUD=$2

    LOGPATH=/opt/log/$DEV
    LOGFILE="$LOGPATH"/$(date +%Y%m%d%H%M%S).log
    
    sudo mkdir -p $LOGPATH
    sudo touch $LOGFILE
    sudo ln -sf $LOGFILE "$LOGPATH".log

    if [ -n $BAUD ];then
        echo minicom -D /dev/$DEV -b $BAUD -w -C $LOGFILE default
        sudo minicom -D /dev/$DEV -b $BAUD -w -C $LOGFILE default
    else        
        echo minicom -D /dev/$DEV -b 115200 -w -C $LOGFILE default
        sudo minicom -D /dev/$DEV -b 115200 -w -C $LOGFILE default
    fi
}

ta()
{
    if ! tmux a -t $@ ;then 
        tmux new -s $@
    fi

}

fn()
{
    find . -iname "$*"
}

alias ts='tmux switch -t'
#alias ta='tmux a -t'
alias tl='tmux ls'
alias fastboot='fastboot.exe'
#alias tn='tmux new -s'
alias ec='setsid eclipse &>/dev/null &'
alias fs='fastboot flash sierra-dual-system'
alias fs1='fastboot flash sierra'
alias fs2='fastboot flash sierra2'
alias ff='fastboot flash'
alias fb1='fastboot flash boot'
alias fb2='fastboot flash boot2'
alias fr='fastboot reboot'
alias fr1='fastboot oem swi-set-ssid 111 && fastboot reboot'
alias fr2='fastboot oem swi-set-ssid 222 && fastboot reboot'
alias fe='fastboot erase'
alias frfs='fastboot flash system'
alias fu='fastboot oem keep-alive && fastboot oem flash-unlock aepa1du5vae1fahb9enohchie+Neer5t'

#alias fn='find . -iname '
alias gn='grep -nr'
alias gi='grep -inr'

export T32SYS=/opt/t32
export T32TMP=/tmp
export T32ID=T32

export PATH=$PATH:/opt/t32/bin/pc_linux64:/home/$USER/usr/bin/t32scipt/

export ADOBE_PATH=/opt/Adobe/Reader9/
export ACROBAT_PATH=/opt/Adobe/Reader9

alias ssh='ssh -X'

sdx55ld()
{
    export PYTHONBIN=/pkg/qct/software/python/2.7/bin
    export PYTHON_PATH=/pkg/qct/software/python/2.7/bin
    export PATH=$PYTHON_PATH:$PATH 
}
ARCH=`uname -m`
[[ $ARCH == "x86_64" && -f ~/.fzf.bash ]] && source ~/.fzf.bash

tmux ls &>/dev/null
[ $? -ne 0 ] && tmux-session restore 

#docker-compose -f ~/cfg/docker/docker-compose.yml up -d

